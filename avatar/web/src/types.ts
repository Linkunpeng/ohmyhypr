// Avatar manifest as delivered by the host: avatar.toml resolved, every path
// rewritten to an http://127.0.0.1 URL the host serves.

export interface Motion {
    url: string;
    loop: boolean;
}

export interface Manifest {
    id: string;
    name: string;
    format: "pmx";
    model: string;
    camera: { target_y: number; distance: number; fov: number };
    // Semantic expression → model morph names. Missing keys are auto-detected.
    expressions: Partial<Record<Expression, string[]>>;
    idle: string[];
    idle_interval: number;
    actions: Record<string, Motion>;
    lines: Record<string, string[]>;
}

// World-space extent of the model; zNear is the z closest to the camera.
export interface Bounds {
    x0: number;
    x1: number;
    y0: number;
    y1: number;
    zNear: number;
}

export type Expression =
    | "blink"
    | "smile"
    | "wink"
    | "angry"
    | "sad"
    | "surprise"
    | "thinking"
    | "mouth_a"
    | "mouth_i"
    | "mouth_u"
    | "mouth_e"
    | "mouth_o";

export interface ThemeVars {
    bubble_bg?: string;
    bubble_fg?: string;
    accent?: string;
    radius?: number;
    font?: string;
}

// host → page
export type Command =
    | { cmd: "load"; manifest: Manifest }
    | { cmd: "say"; text: string }
    | { cmd: "stream"; chunk: string }
    | { cmd: "stream_end" }
    | { cmd: "thinking"; on: boolean }
    | { cmd: "motion"; name: string }
    | { cmd: "expression"; name: Expression }
    | { cmd: "chat" }
    | { cmd: "theme"; vars: ThemeVars };

export interface Rect {
    x: number;
    y: number;
    w: number;
    h: number;
}

// page → host
export type Event =
    | { type: "ready" }
    | { type: "loaded"; morphs: string[]; bones: number }
    | { type: "error"; message: string }
    | { type: "debug"; message: string }
    | { type: "region"; rects: Rect[] }
    | { type: "drag"; dx: number; dy: number }
    | { type: "drag_end" }
    | { type: "chat"; text: string }
    | { type: "menu"; action: string };
