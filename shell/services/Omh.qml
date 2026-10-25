pragma Singleton

// Shared shell state plus helpers for talking to Hyprland and the brain.

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    property bool omniboxOpen: false

    // Hyprland 0.56 Lua config: dispatch takes a Lua expression, not the
    // legacy "workspace 3" syntax.
    function dispatch(luaExpr: string): void {
        Hyprland.dispatch(luaExpr);
    }

    function focusWorkspace(id: int): void {
        dispatch("hl.dsp.focus({ workspace = " + id + " })");
    }

    function notify(summary: string, body: string): void {
        Quickshell.execDetached(["notify-send", "-a", "ohmyhypr", summary, body]);
    }
}
