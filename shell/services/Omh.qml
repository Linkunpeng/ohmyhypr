pragma Singleton

// Shared shell state plus helpers for talking to Hyprland and the brain.

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    property bool omniboxOpen: false
    property bool themePickerOpen: false
    property bool wallpaperPickerOpen: false
    property bool barHidden: false
    property string wallpaperTargetScreen: ""

    function toggleWallpaperPicker(): void {
        if (!wallpaperPickerOpen)
            wallpaperTargetScreen = Hyprland.focusedMonitor?.name ?? "";
        wallpaperPickerOpen = !wallpaperPickerOpen;
    }

    // <repo>/bin/omh runs the brain CLI from this checkout. (Qt.resolvedUrl
    // returns qrc:/qs-blackhole paths under Quickshell; use shellDir.)
    readonly property string repo: Quickshell.shellDir.replace(/\/shell\/?$/, "/")
    readonly property string omh: repo + "bin/omh"

    // Hyprland 0.56 Lua config: dispatch takes a Lua expression, not the
    // legacy "workspace 3" syntax.
    function dispatch(luaExpr: string): void {
        Hyprland.dispatch(luaExpr);
    }

    function focusWorkspace(id: int): void {
        dispatch("hl.dsp.focus({ workspace = " + id + " })");
    }

    function run(args: list<string>): void {
        Quickshell.execDetached([omh, ...args]);
    }

    function notify(summary: string, body: string): void {
        Quickshell.execDetached(["notify-send", "-a", "ohmyhypr", summary, body]);
    }
}
