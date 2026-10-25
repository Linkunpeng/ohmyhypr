import { ArcRotateCamera } from "@babylonjs/core/Cameras/arcRotateCamera";
import { Engine } from "@babylonjs/core/Engines/engine";
import { DirectionalLight } from "@babylonjs/core/Lights/directionalLight";
import { HemisphericLight } from "@babylonjs/core/Lights/hemisphericLight";
import { Color3, Color4 } from "@babylonjs/core/Maths/math.color";
import { Matrix, Vector3 } from "@babylonjs/core/Maths/math.vector";
import { Scene } from "@babylonjs/core/scene";
import { RegisterDxBmpTextureLoader } from "babylon-mmd/esm/Loader/registerDxBmpTextureLoader";
import { SdefInjector } from "babylon-mmd/esm/Loader/sdefInjector";

import type { Manifest, Rect } from "./types";

export class Stage {
    readonly engine: Engine;
    readonly scene: Scene;
    readonly camera: ArcRotateCamera;
    private distance = 30;
    private zoom = 1;

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

        window.addEventListener("resize", () => this.engine.resize());
        this.engine.runRenderLoop(() => this.scene.render());
    }

    frame(manifest: Manifest): void {
        const cam = manifest.camera;
        this.distance = cam.distance;
        this.camera.target.set(0, cam.target_y, 0);
        this.camera.fov = cam.fov;
        this.applyZoom();
    }

    zoomBy(factor: number): void {
        this.zoom = Math.min(2.5, Math.max(0.5, this.zoom * factor));
        this.applyZoom();
    }

    private applyZoom(): void {
        this.camera.radius = this.distance * this.zoom;
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
