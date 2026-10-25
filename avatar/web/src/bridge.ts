import type { Command, Event } from "./types";

interface WebkitHandlers {
    webkit?: { messageHandlers?: { omh?: { postMessage(msg: string): void } } };
}

export function post(event: Event): void {
    const handler = (window as unknown as WebkitHandlers).webkit?.messageHandlers?.omh;
    if (handler) {
        handler.postMessage(JSON.stringify(event));
    } else {
        console.debug("omh →", event);
    }
}

// The host calls window.omh(cmd) via evaluate_javascript.
export function listen(handler: (cmd: Command) => void): void {
    (window as unknown as { omh: (cmd: Command) => void }).omh = (cmd) => {
        try {
            handler(cmd);
        } catch (e) {
            post({ type: "error", message: String(e) });
        }
    };
}
