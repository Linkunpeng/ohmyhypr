// DOM overlay: speech bubble, chat input, context menu, pointer gestures.

import type { ThemeVars } from "./types";

const $ = <T extends HTMLElement>(id: string) => document.getElementById(id) as T;

export class Ui {
    readonly bubble = $<HTMLDivElement>("bubble");
    readonly bubbleText = $<HTMLDivElement>("bubble-text");
    readonly chat = $<HTMLFormElement>("chat");
    readonly chatInput = $<HTMLInputElement>("chat-input");
    readonly menu = $<HTMLUListElement>("menu");
    private hideTimer = 0;

    say(text: string, append = false): number {
        this.chat.hidden = true;
        this.bubble.hidden = false;
        this.bubbleText.textContent = append ? (this.bubbleText.textContent ?? "") + text : text;
        this.bubbleText.scrollTop = this.bubbleText.scrollHeight;
        // reading time grows with length; caller uses it for mouth animation too
        const seconds = Math.min(12, 1.5 + [...text].length * 0.12);
        this.scheduleHide(seconds + 3);
        return seconds;
    }

    openChat(onSubmit: (text: string) => void): void {
        window.clearTimeout(this.hideTimer);
        this.bubble.hidden = false;
        this.bubbleText.textContent = this.bubbleText.textContent || "……什么事？";
        this.chat.hidden = false;
        this.chatInput.value = "";
        this.chatInput.focus();
        this.chat.onsubmit = (e) => {
            e.preventDefault();
            const text = this.chatInput.value.trim();
            if (!text) return;
            this.chat.hidden = true;
            this.bubbleText.textContent = "";
            onSubmit(text);
        };
        this.chatInput.onkeydown = (e) => {
            if (e.key === "Escape") this.hide();
        };
    }

    hide(): void {
        this.bubble.hidden = true;
        this.chat.hidden = true;
    }

    private scheduleHide(seconds: number): void {
        window.clearTimeout(this.hideTimer);
        this.hideTimer = window.setTimeout(() => {
            if (this.chat.hidden) this.bubble.hidden = true;
        }, seconds * 1000);
    }

    placeBubble(headX: number, headY: number): void {
        const height = this.bubble.offsetHeight;
        const top = Math.max(6, headY - height - 28);
        this.bubble.style.top = `${top}px`;
        this.bubble.style.left = `${Math.min(Math.max(headX, 90), window.innerWidth - 90)}px`;
    }

    showMenu(x: number, y: number, items: [string, string][], onPick: (action: string) => void): void {
        this.menu.replaceChildren(
            ...items.map(([action, label]) => {
                const li = document.createElement("li");
                li.textContent = label;
                li.onclick = () => {
                    this.menu.hidden = true;
                    onPick(action);
                };
                return li;
            }),
        );
        this.menu.hidden = false;
        this.menu.style.left = `${Math.min(x, window.innerWidth - this.menu.offsetWidth - 4)}px`;
        this.menu.style.top = `${Math.min(y, window.innerHeight - this.menu.offsetHeight - 4)}px`;
    }

    applyTheme(vars: ThemeVars): void {
        const root = document.documentElement.style;
        if (vars.bubble_bg) root.setProperty("--bubble-bg", vars.bubble_bg);
        if (vars.bubble_fg) root.setProperty("--bubble-fg", vars.bubble_fg);
        if (vars.accent) root.setProperty("--accent", vars.accent);
        if (vars.radius !== undefined) root.setProperty("--radius", `${vars.radius}px`);
        if (vars.font) root.setProperty("--font", vars.font);
    }

    rectOf(el: HTMLElement): { x: number; y: number; w: number; h: number } | null {
        if (el.hidden) return null;
        const r = el.getBoundingClientRect();
        return { x: r.left, y: r.top, w: r.width, h: r.height };
    }
}

export interface Gestures {
    click(x: number, y: number): void;
    doubleClick(): void;
    menu(x: number, y: number): void;
    drag(dx: number, dy: number): void;
    dragEnd(): void;
    rotate(dx: number): void;
    hover(x: number, y: number): void;
    wheel(delta: number): void;
}

const LEFT = 0;
const RIGHT = 2;

// Left drag moves the host window, so the pointer stays at the same window-relative
// position; its deltas are always measured from the press point. Right drag spins
// the model (incremental deltas). A press that never passes the drag threshold is a
// click (left) or opens the menu on release (right).
export function bindGestures(el: HTMLElement, g: Gestures): void {
    let down: { x: number; y: number; button: number } | null = null;
    let lastX = 0;
    let dragging = false;
    let clickTimer = 0;

    el.addEventListener("pointerdown", (e) => {
        if (down || (e.button !== LEFT && e.button !== RIGHT)) return;
        down = { x: e.clientX, y: e.clientY, button: e.button };
        lastX = e.clientX;
        dragging = false;
        el.setPointerCapture(e.pointerId);
    });
    el.addEventListener("pointermove", (e) => {
        if (down?.button !== RIGHT) g.hover(e.clientX, e.clientY);
        if (!down) return;
        const dx = e.clientX - down.x;
        const dy = e.clientY - down.y;
        if (!dragging && Math.hypot(dx, dy) > 5) dragging = true;
        if (!dragging) return;
        if (down.button === LEFT) g.drag(dx, dy);
        else g.rotate(e.clientX - lastX);
        lastX = e.clientX;
    });
    el.addEventListener("pointerup", (e) => {
        if (!down) return;
        const { button } = down;
        const wasDrag = dragging;
        down = null;
        dragging = false;
        if (button === RIGHT) {
            if (!wasDrag) g.menu(e.clientX, e.clientY);
            return;
        }
        if (wasDrag) {
            g.dragEnd();
            return;
        }
        if (clickTimer) {
            window.clearTimeout(clickTimer);
            clickTimer = 0;
            g.doubleClick();
        } else {
            const { clientX: x, clientY: y } = e;
            clickTimer = window.setTimeout(() => {
                clickTimer = 0;
                g.click(x, y);
            }, 250);
        }
    });
    el.addEventListener("pointercancel", () => {
        if (down?.button === LEFT && dragging) g.dragEnd();
        down = null;
        dragging = false;
    });
    // The menu opens on right-button release instead, so a right drag can rotate.
    el.addEventListener("contextmenu", (e) => e.preventDefault());
    el.addEventListener("wheel", (e) => {
        e.preventDefault();
        g.wheel(e.deltaY);
    }, { passive: false });
}
