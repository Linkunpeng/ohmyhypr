import { ArcRotateCamera } from "@babylonjs/core/Cameras/arcRotateCamera";
import { Engine } from "@babylonjs/core/Engines/engine";
import { DirectionalLight } from "@babylonjs/core/Lights/directionalLight";
import { HemisphericLight } from "@babylonjs/core/Lights/hemisphericLight";
import { Color3, Color4 } from "@babylonjs/core/Maths/math.color";
import { Matrix, Vector3 } from "@babylonjs/core/Maths/math.vector";
import { Scene } from "@babylonjs/core/scene";
import { RegisterDxBmpTextureLoader } from "babylon-mmd/esm/Loader/registerDxBmpTextureLoader";
import { SdefInjector } from "babylon-mmd/esm/Loader/sdefInjector";

import type { Bounds, Manifest, Rect } from "./types";

const MARGIN = 0.04; // fraction of the view kept clear around the body

// Clamp v into [lo, hi]; if the interval is empty, its midpoint.
const within = (v: number, lo: number, hi: number) => (lo > hi ? (lo + hi) / 2 : Math.min(hi, Math.max(lo, v)));

export class Stage {
    readonly engine: Engine;
    readonly scene: Scene;
    readonly camera: ArcRotateCamera;
    private distance = 30;
    private targetY = 12;
    private zoom = 1;
    // Auto-framing: where the camera wants to be so the whole body stays in view.
    private want = { x: 0, y: 12, radius: 30 };

    constructor(readonly canvas: HTMLCanvasElement) {
        this.engine = new Engine(canvas, true, { alpha: true, premultipliedAlpha: true }, true);
        SdefInjector.OverrideEngineCreateEffect(this.engine);
        RegisterDxBmpTextureLoader();

        this.scene = new Scene(this.engine);
        this.scene.clearColor = new Color4(0, 0, 0, 0);
        this.scene.ambientColor = new Color3(0.5, 0.5, 0.5);

        this.camera = new ArcRotateCamera("camera", -Math.PI / 2, Math.PI / 2, 30, new Vector3(0, 12, 0), this.scene);
        this.camera.minZ = 0.5;

        const sun = new DirectionalLight("sun", new Vector3(0.5, -1, 1), this.scene);
        sun.intensity = 0.9;
        const sky = new HemisphericLight("sky", new Vector3(0, 1, 0), this.scene);
        sky.intensity = 0.25;

        this.scene.onBeforeRenderObservable.add(() => this.follow(this.engine.getDeltaTime() / 1000));
        window.addEventListener("resize", () => this.engine.resize());
        this.engine.runRenderLoop(() => this.scene.render());
    }

    frame(manifest: Manifest): void {
        const cam = manifest.camera;
        this.distance = cam.distance;
        this.targetY = cam.target_y;
        this.camera.fov = cam.fov;
        this.want = { x: 0, y: this.targetY, radius: this.baseRadius };
        this.camera.target.set(0, this.targetY, 0);
        this.camera.radius = this.baseRadius;
    }

    zoomBy(factor: number): void {
        this.zoom = Math.min(2.5, Math.max(0.5, this.zoom * factor));
    }

    private get baseRadius(): number {
        return this.distance * this.zoom;
    }

    // Keep the body (world-space extent) inside the fixed-size window: pan as
    // little as possible away from the pack's framing, and back the camera off
    // only when the body no longer fits (wide dance moves, zooming in).
    fit(b: Bounds | null): void {
        const base = this.baseRadius;
        if (!b) {
            this.want = { x: 0, y: this.targetY, radius: base };
            return;
        }
        const ky = Math.tan(this.camera.fov / 2) * (1 - MARGIN);
        const kx = ky * this.engine.getAspectRatio(this.camera);
        // The camera sits at z = -radius looking +z, so a point's depth is radius + z.
        const radius = Math.max(base, (b.x1 - b.x0) / 2 / kx - b.zNear, (b.y1 - b.y0) / 2 / ky - b.zNear);
        const depth = Math.max(1, radius + b.zNear);
        this.want = {
            x: within(0, b.x1 - kx * depth, b.x0 + kx * depth),
            y: within(this.targetY, b.y1 - ky * depth, b.y0 + ky * depth),
            radius,
        };
    }

    // Ease toward the framing: back off fast so nothing gets clipped, return slowly.
    private follow(dt: number): void {
        const cam = this.camera;
        const w = this.want;
        const ease = (rate: number) => Math.min(1, dt * rate);
        cam.radius += (w.radius - cam.radius) * ease(w.radius > cam.radius ? 6 : 1.5);
        cam.target.x += (w.x - cam.target.x) * ease(4);
        cam.target.y += (w.y - cam.target.y) * ease(4);
    }

    project(p: Vector3): { x: number; y: number } {
        const w = this.engine.getRenderWidth();
        const h = this.engine.getRenderHeight();
        const s = Vector3.Project(p, Matrix.IdentityReadOnly, this.scene.getTransformMatrix(), this.camera.viewport.toGlobal(w, h));
        const ratio = this.canvas.clientWidth / w;
        return { x: s.x * ratio, y: s.y * ratio };
    }

    // Screen rect (CSS px) covering a world-space box.
    projectBox(min: Vector3, max: Vector3): Rect {
        let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
        for (const x of [min.x, max.x]) for (const y of [min.y, max.y]) for (const z of [min.z, max.z]) {
            const p = this.project(new Vector3(x, y, z));
            x0 = Math.min(x0, p.x); y0 = Math.min(y0, p.y);
            x1 = Math.max(x1, p.x); y1 = Math.max(y1, p.y);
        }
        return { x: x0, y: y0, w: x1 - x0, h: y1 - y0 };
    }
}
