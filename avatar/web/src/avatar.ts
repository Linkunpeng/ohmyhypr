// MMD avatar: model loading, motion director (crossfaded composite animation),
// and procedural life (blink, talking mouth, expressions, turning to the pointer).

import type { AssetContainer } from "@babylonjs/core/assetContainer";
import { LoadAssetContainerAsync } from "@babylonjs/core/Loading/sceneLoader";
import { Quaternion, Vector3 } from "@babylonjs/core/Maths/math.vector";
import type { Mesh } from "@babylonjs/core/Meshes/mesh";
import type { Scene } from "@babylonjs/core/scene";
// Babylon 9 / babylon-mmd split modules into *.pure + registering side effects;
// these imports register the material builder, outline (toon edge), SDEF, PMX loader.
import "@babylonjs/core/Materials/standardMaterial";
import "babylon-mmd/esm/Loader/mmdModelLoader";
import "babylon-mmd/esm/Loader/mmdOutlineRenderer";
import "babylon-mmd/esm/Loader/sdefMesh";
import "babylon-mmd/esm/Loader/pmxLoader";
import "babylon-mmd/esm/Runtime/Animation/mmdCompositeRuntimeModelAnimation";
import "babylon-mmd/esm/Runtime/Animation/mmdRuntimeModelAnimation";
import type { MmdAnimation } from "babylon-mmd/esm/Loader/Animation/mmdAnimation";
import { VmdLoader } from "babylon-mmd/esm/Loader/vmdLoader";
import { VpdLoader } from "babylon-mmd/esm/Loader/vpdLoader";
import { MmdAnimationSpan, MmdCompositeAnimation } from "babylon-mmd/esm/Runtime/Animation/mmdCompositeAnimation";
import { MmdStandardMaterialProxy } from "babylon-mmd/esm/Runtime/mmdStandardMaterialProxy";
import { MmdWasmInstanceTypeSPR } from "babylon-mmd/esm/Runtime/Optimized/InstanceType/singlePhysicsRelease";
import { GetMmdWasmInstance } from "babylon-mmd/esm/Runtime/Optimized/mmdWasmInstance";
import type { MmdWasmModel } from "babylon-mmd/esm/Runtime/Optimized/mmdWasmModel";
import { MmdWasmRuntime } from "babylon-mmd/esm/Runtime/Optimized/mmdWasmRuntime";
import { MmdWasmPhysics } from "babylon-mmd/esm/Runtime/Optimized/Physics/mmdWasmPhysics";

import type { Bounds, Expression, Manifest } from "./types";

// Common morph names in MMD models, tried in order when the manifest omits one.
const MORPH_CANDIDATES: Record<Expression, string[]> = {
    blink: ["まばたき", "瞬き", "blink", "Blink"],
    smile: ["笑い", "にこり", "微笑", "smile"],
    wink: ["ウィンク", "ウィンク２", "wink"],
    angry: ["怒り", "angry"],
    sad: ["困る", "悲しい", "sad"],
    surprise: ["びっくり", "驚き", "surprise"],
    thinking: [],
    mouth_a: ["あ", "a"],
    mouth_i: ["い", "i"],
    mouth_u: ["う", "u"],
    mouth_e: ["え", "e"],
    mouth_o: ["お", "o"],
};
const MOUTHS: Expression[] = ["mouth_a", "mouth_i", "mouth_u", "mouth_e", "mouth_o"];
const MOODS: Expression[] = ["smile", "angry", "sad", "surprise", "wink"];

const FPS = 30; // MMD frame rate
const FADE = 12; // crossfade length in frames
const FOREVER = 30 * 60 * 60 * 24 * 7;
// Padding (MMD units) from the skeleton out to the mesh: hair above the head
// bone, fingers and skirt at the sides.
const PAD = { side: 1.5, top: 2.5, bottom: 0.5 };

type Animation = MmdAnimation;

export class Avatar {
    manifest: Manifest | null = null;
    model: MmdWasmModel | null = null;

    private container: AssetContainer | null = null;
    private mesh: Mesh | null = null;
    private composite: MmdCompositeAnimation | null = null;
    private baseSpan: MmdAnimationSpan | null = null;
    private actionSpan: MmdAnimationSpan | null = null;
    private idleAnims: Animation[] = [];
    private idleIndex = 0;
    private idleTimer = 0;
    private actionAnims = new Map<string, Animation>();
    private morphs = new Map<Expression, string[]>();

    private targets = new Map<string, number>(); // morph name → target weight
    private weights = new Map<string, number>(); // morph name → current weight
    private nextBlink = 0;
    private talkingUntil = 0;
    private nextMouth = 0;
    private expressionUntil = 0;
    private yaw = 0;
    private yawTarget = 0;
    private spin = 0; // user rotation (right-drag), on top of turning to the pointer
    private hop = 0;
    private scratch = new Vector3();

    private constructor(
        readonly scene: Scene,
        readonly runtime: MmdWasmRuntime,
    ) {
        scene.onBeforeRenderObservable.add(() => this.tick(scene.getEngine().getDeltaTime() / 1000));
    }

    static async create(scene: Scene): Promise<Avatar> {
        const wasm = await GetMmdWasmInstance(new MmdWasmInstanceTypeSPR());
        const runtime = new MmdWasmRuntime(wasm, scene, new MmdWasmPhysics(scene));
        runtime.register(scene);
        return new Avatar(scene, runtime);
    }

    get morphNames(): string[] {
        return this.model?.morph.morphs.map((m) => m.name) ?? [];
    }

    get root(): Mesh | null {
        return this.mesh;
    }

    async load(manifest: Manifest): Promise<void> {
        this.unload();
        this.manifest = manifest;

        const container = await LoadAssetContainerAsync(manifest.model, this.scene);
        container.addAllToScene();
        this.container = container;
        this.mesh = container.meshes[0] as Mesh;
        this.mesh.rotationQuaternion = Quaternion.Identity();
        this.model = this.runtime.createMmdModel(this.mesh, {
            materialProxyConstructor: MmdStandardMaterialProxy,
        });

        this.resolveMorphs(manifest);

        const vpd = new VpdLoader(this.scene);
        const vmd = new VmdLoader(this.scene);
        const loadMotion = (url: string, name: string) =>
            url.toLowerCase().endsWith(".vpd") ? vpd.loadAsync(name, url) : vmd.loadAsync(name, url);

        this.idleAnims = await Promise.all(manifest.idle.map((url, i) => loadMotion(url, `idle-${i}`)));
        for (const [name, motion] of Object.entries(manifest.actions)) {
            this.actionAnims.set(name, await loadMotion(motion.url, name));
        }

        this.composite = new MmdCompositeAnimation("omh");
        this.model.setRuntimeAnimation(this.model.createRuntimeAnimation(this.composite));
        if (this.idleAnims.length > 0) {
            this.setBase(this.idleAnims[0], 0);
        }
        // Spans come and go; keep one endless timeline instead of the composite's length.
        this.runtime.setManualAnimationDuration(FOREVER);
        await this.runtime.playAnimation();
        this.idleTimer = manifest.idle_interval;
    }

    unload(): void {
        if (this.model) {
            this.runtime.destroyMmdModel(this.model);
        }
        this.container?.dispose();
        this.model = null;
        this.mesh = null;
        this.container = null;
        this.composite = null;
        this.baseSpan = null;
        this.actionSpan = null;
        this.idleAnims = [];
        this.actionAnims.clear();
        this.morphs.clear();
        this.targets.clear();
        this.weights.clear();
    }

    // ---- motions -----------------------------------------------------------

    get actions(): string[] {
        return [...this.actionAnims.keys()];
    }

    get isActing(): boolean {
        return this.actionSpan !== null;
    }

    nextIdle(): void {
        if (this.idleAnims.length < 2 || this.isActing) return;
        this.idleIndex = (this.idleIndex + 1) % this.idleAnims.length;
        this.setBase(this.idleAnims[this.idleIndex], FADE);
    }

    play(name: string): boolean {
        const anim = this.actionAnims.get(name);
        if (!anim || !this.composite) return false;
        this.stopAction();
        const now = this.runtime.currentFrameTime;
        const span = new MmdAnimationSpan(anim, anim.startFrame, anim.endFrame, now - anim.startFrame, 1);
        span.easeInFrameTime = FADE;
        span.easeOutFrameTime = FADE;
        this.composite.addSpan(span);
        this.actionSpan = span;
        this.fadeOutBase(now);
        return true;
    }

    stopAction(): void {
        if (!this.actionSpan || !this.composite) return;
        const now = this.runtime.currentFrameTime;
        const span = this.actionSpan;
        span.endFrame = Math.min(span.endFrame, now - span.offset + FADE);
        this.actionSpan = null;
        this.setBase(this.idleAnims[this.idleIndex], FADE);
    }

    private setBase(anim: Animation | undefined, fade: number): void {
        if (!anim || !this.composite) return;
        const now = this.runtime.currentFrameTime;
        this.fadeOutBase(now);
        const span = new MmdAnimationSpan(anim, 0, FOREVER, now, 1);
        span.easeInFrameTime = fade;
        this.composite.addSpan(span);
        this.baseSpan = span;
    }

    private fadeOutBase(now: number): void {
        const old = this.baseSpan;
        if (!old) return;
        old.endFrame = now - old.offset + FADE;
        old.easeOutFrameTime = FADE;
        this.baseSpan = null;
    }

    private pruneSpans(now: number): void {
        if (!this.composite) return;
        for (const span of [...this.composite.spans]) {
            if (span.offset + span.endFrame < now - 1) {
                this.composite.removeSpan(span);
            }
        }
        const action = this.actionSpan;
        if (action && action.offset + action.endFrame - FADE <= now) {
            const loop = this.manifest?.actions[action.name]?.loop;
            this.actionSpan = null;
            if (loop) {
                this.play(action.name);
            } else {
                this.setBase(this.idleAnims[this.idleIndex], FADE);
            }
        }
    }

    // ---- expressions & talking ---------------------------------------------

    private resolveMorphs(manifest: Manifest): void {
        const available = new Set(this.morphNames);
        for (const [expr, candidates] of Object.entries(MORPH_CANDIDATES) as [Expression, string[]][]) {
            const explicit = (manifest.expressions[expr] ?? []).filter((m) => available.has(m));
            const auto = candidates.find((c) => available.has(c));
            const names = explicit.length ? explicit : auto ? [auto] : [];
            if (names.length) this.morphs.set(expr, names);
        }
    }

    express(expr: Expression, seconds = 2.5): void {
        for (const e of MOODS) this.setTarget(e, e === expr ? 1 : 0);
        this.expressionUntil = performance.now() / 1000 + seconds;
    }

    think(on: boolean): void {
        this.setTarget("thinking", on ? 1 : 0);
    }

    talk(seconds: number): void {
        this.talkingUntil = Math.max(this.talkingUntil, performance.now() / 1000 + seconds);
    }

    hopOnce(): void {
        this.hop = 1;
    }

    lookAt(nx: number): void {
        // nx: pointer x in [-1, 1] across the window
        this.yawTarget = Math.max(-1, Math.min(1, nx)) * 0.35;
    }

    spinBy(radians: number): void {
        this.spin = (this.spin + radians) % (Math.PI * 2);
    }

    private setTarget(expr: Expression, weight: number): void {
        for (const morph of this.morphs.get(expr) ?? []) this.targets.set(morph, weight);
    }

    // ---- per frame -----------------------------------------------------------

    private tick(dt: number): void {
        if (!this.model || !this.mesh) return;
        const t = performance.now() / 1000;

        this.pruneSpans(this.runtime.currentFrameTime);

        this.idleTimer -= dt;
        if (this.idleTimer <= 0 && this.manifest) {
            this.idleTimer = this.manifest.idle_interval;
            this.nextIdle();
        }

        // blink
        if (t >= this.nextBlink) {
            this.setTarget("blink", 1);
            if (t >= this.nextBlink + 0.12) {
                this.setTarget("blink", 0);
                this.nextBlink = t + 2.5 + Math.random() * 4;
            }
        }

        // talking mouth: random vowel shapes
        if (t < this.talkingUntil) {
            if (t >= this.nextMouth) {
                const open = MOUTHS[Math.floor(Math.random() * MOUTHS.length)];
                for (const m of MOUTHS) this.setTarget(m, m === open ? 0.4 + Math.random() * 0.5 : 0);
                this.nextMouth = t + 0.07 + Math.random() * 0.08;
            }
        } else {
            for (const m of MOUTHS) this.setTarget(m, 0);
        }

        if (this.expressionUntil && t >= this.expressionUntil) {
            this.expressionUntil = 0;
            for (const e of MOODS) this.setTarget(e, 0);
        }

        // ease morph weights toward targets
        const k = Math.min(1, dt * 18);
        for (const [name, target] of this.targets) {
            const w = this.weights.get(name) ?? 0;
            const next = w + (target - w) * k;
            if (Math.abs(next - w) > 1e-3 || next !== w) {
                this.weights.set(name, next);
                this.model.morph.setMorphWeight(name, next);
            }
        }

        // turn toward the pointer, hop on click
        this.yaw += (this.yawTarget - this.yaw) * Math.min(1, dt * 3);
        Quaternion.FromEulerAnglesToRef(0, this.spin + this.yaw, 0, this.mesh.rotationQuaternion!);
        if (this.hop > 0) {
            this.hop = Math.max(0, this.hop - dt * 2.5);
            this.mesh.position.y = Math.sin((1 - this.hop) * Math.PI) * 0.8;
        }
    }

    // World-space extent of the posed skeleton, padded out to the mesh.
    bounds(): Bounds | null {
        if (!this.model || !this.mesh) return null;
        const world = this.mesh.getWorldMatrix();
        const p = this.scratch;
        const b = { x0: Infinity, x1: -Infinity, y0: Infinity, y1: -Infinity, zNear: Infinity };
        for (const bone of this.model.runtimeBones) {
            bone.getWorldTranslationToRef(p);
            Vector3.TransformCoordinatesToRef(p, world, p);
            b.x0 = Math.min(b.x0, p.x); b.x1 = Math.max(b.x1, p.x);
            b.y0 = Math.min(b.y0, p.y); b.y1 = Math.max(b.y1, p.y);
            b.zNear = Math.min(b.zNear, p.z);
        }
        if (!Number.isFinite(b.x0)) return null;
        b.x0 -= PAD.side; b.x1 += PAD.side;
        b.y0 -= PAD.bottom; b.y1 += PAD.top;
        b.zNear -= PAD.side;
        return b;
    }

    headPosition(out: Vector3): Vector3 | null {
        const bone = this.model?.runtimeBones.find((b) => b.name === "頭");
        if (!bone || !this.mesh) return null;
        bone.getWorldTranslationToRef(out);
        return Vector3.TransformCoordinatesToRef(out, this.mesh.getWorldMatrix(), out);
    }
}

export { FPS };
