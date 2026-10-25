import { Vector3 } from "@babylonjs/core/Maths/math.vector";

import { Avatar } from "./avatar";
import { listen, post } from "./bridge";
import { Stage } from "./stage";
import type { Command, Rect } from "./types";
import { bindGestures, Ui } from "./ui";

const pick = <T>(xs: T[] | undefined): T | undefined => (xs && xs.length ? xs[Math.floor(Math.random() * xs.length)] : undefined);

// Forward renderer console noise to the host log (shows up in `omh avatar run` stderr).
for (const level of ["error", "warn"] as const) {
    const orig = console[level].bind(console);
    console[level] = (...args: unknown[]) => {
        orig(...args);
        post({ type: "debug", message: `console.${level}: ${args.map(String).join(" ")}`.slice(0, 500) });
    };
}

async function main(): Promise<void> {
    const canvas = document.getElementById("stage") as HTMLCanvasElement;
    const stage = new Stage(canvas);
    const ui = new Ui();
    const avatar = await Avatar.create(stage.scene);

    let bodyRect: Rect | null = null;
    let clicks: number[] = [];
    let streaming = false;
    const head = new Vector3();

    const say = (text: string) => {
        const seconds = ui.say(text);
        avatar.talk(seconds);
    };

    const startChat = () =>
        ui.openChat((text) => {
            streaming = false;
            avatar.think(true);
            post({ type: "chat", text });
        });

    // Input region: model body + overlays. Everything else clicks through.
    const publishRegion = () => {
        const rects = [bodyRect, ui.rectOf(ui.bubble), ui.rectOf(ui.menu)].filter((r): r is Rect => r !== null);
        post({ type: "region", rects: rects.map((r) => ({ x: Math.floor(r.x), y: Math.floor(r.y), w: Math.ceil(r.w), h: Math.ceil(r.h) })) });
    };
    let lastRegion = "";
    stage.scene.onAfterRenderObservable.add(() => {
        if (avatar.headPosition(head)) {
            const p = stage.project(head);
            ui.placeBubble(p.x, p.y);
        }
    });
    window.setInterval(() => {
        const key = JSON.stringify([bodyRect, ui.rectOf(ui.bubble), ui.rectOf(ui.menu)]);
        if (key !== lastRegion) {
            lastRegion = key;
            publishRegion();
        }
    }, 200);

    // Hit region = projected skeleton extent (follows poses and dances), padded.
    const bonePos = new Vector3();
    const measureBody = () => {
        const model = avatar.model;
        const mesh = avatar.root;
        if (!model || !mesh) return;
        const world = mesh.getWorldMatrix();
        let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
        for (const bone of model.runtimeBones) {
            bone.getWorldTranslationToRef(bonePos);
            Vector3.TransformCoordinatesToRef(bonePos, world, bonePos);
            const p = stage.project(bonePos);
            x0 = Math.min(x0, p.x); y0 = Math.min(y0, p.y);
            x1 = Math.max(x1, p.x); y1 = Math.max(y1, p.y);
        }
        const pad = 24;
        bodyRect = { x: x0 - pad, y: y0 - pad * 2, w: x1 - x0 + pad * 2, h: y1 - y0 + pad * 3 };
    };
    window.setInterval(measureBody, 400);

    bindGestures(canvas, {
        click() {
            const now = performance.now();
            clicks = [...clicks.filter((t) => now - t < 1500), now];
            const lines = avatar.manifest?.lines ?? {};
            if (clicks.length >= 3) {
                clicks = [];
                avatar.express("angry");
                say(pick(lines.poke) ?? "……");
            } else {
                avatar.express("smile");
                avatar.hopOnce();
                say(pick(lines.click) ?? "……");
            }
        },
        doubleClick: startChat,
        menu(x, y) {
            const items: [string, string][] = [["chat", "💬 聊天"], ["pose", "🔄 换个姿势"]];
            for (const name of avatar.actions) {
                items.push([`action:${name}`, avatar.isActing ? "⏹ 停下" : `✨ ${name}`]);
            }
            items.push(["reload", "♻ 重新加载"], ["hide", "🙈 隐藏"]);
            ui.showMenu(x, y, items, (action) => {
                if (action === "chat") startChat();
                else if (action === "pose") avatar.nextIdle();
                else if (action.startsWith("action:")) {
                    if (avatar.isActing) avatar.stopAction();
                    else avatar.play(action.slice(7));
                } else post({ type: "menu", action });
            });
        },
        drag: (dx, dy) => post({ type: "drag", dx, dy }),
        dragEnd: () => post({ type: "drag_end" }),
        hover: (x) => avatar.lookAt((x / window.innerWidth) * 2 - 1),
        wheel(delta) {
            stage.zoomBy(delta > 0 ? 1.08 : 1 / 1.08);
            measureBody();
        },
    });
    document.addEventListener("pointerdown", (e) => {
        if (!ui.menu.contains(e.target as Node)) ui.menu.hidden = true;
    });

    listen(async (cmd: Command) => {
        switch (cmd.cmd) {
            case "load":
                try {
                    await avatar.load(cmd.manifest);
                    stage.frame(cmd.manifest);
                    post({ type: "loaded", morphs: avatar.morphNames, bones: avatar.model?.runtimeBones.length ?? 0 });
                    const greet = pick(cmd.manifest.lines.greet);
                    if (greet) window.setTimeout(() => say(greet), 1200);
                } catch (e) {
                    post({ type: "error", message: `load failed: ${e}` });
                }
                break;
            case "say":
                say(cmd.text);
                break;
            case "thinking":
                avatar.think(cmd.on);
                break;
            case "stream":
                avatar.think(false);
                ui.say(cmd.chunk, streaming);
                streaming = true;
                avatar.talk(0.6);
                break;
            case "stream_end":
                streaming = false;
                break;
            case "motion":
                if (cmd.name === "next") avatar.nextIdle();
                else if (cmd.name === "stop") avatar.stopAction();
                else avatar.play(cmd.name);
                break;
            case "expression":
                avatar.express(cmd.name);
                break;
            case "chat":
                startChat();
                break;
            case "theme":
                ui.applyTheme(cmd.vars);
                break;
        }
    });

    post({ type: "ready" });
}

main().catch((e) => post({ type: "error", message: String(e?.stack ?? e) }));
