pragma Singleton

// Look of the status bar, ported from JaKooLit's waybar style
// "[Dark] Latte-Wallust combined". Waybar takes the border and volume colors from
// wallust (wallpaper colors 12 and 13); here they follow the theme palette instead.

import QtQuick
import Quickshell

Singleton {
    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 13

    readonly property int marginTop: 3
    readonly property int marginSide: 8
    readonly property int boxHeight: 34       // .modules-*: 2px top padding + 30px content + 2px border
    readonly property int moduleHeight: 30
    readonly property int radius: 15
    readonly property int spacing: 3
    readonly property int padding: 6

    readonly property color background: Qt.rgba(1 / 255, 1 / 255, 1 / 255, 0.5)
    readonly property color border: Theme.accent        // wallust color12
    readonly property color volume: Theme.accentAlt     // wallust color13
    readonly property color text: "#e5d9f5"
    readonly property color inactive: "#6e6a86"
    readonly property color gold: "#ffd700"
    readonly property color sapphire: "#209fb5"
    readonly property color mauve: "#8839ef"
    readonly property color sky: "#04a5e5"
    readonly property color teal: "#179299"
    readonly property color neon: "#39ff14"
    readonly property color red: "#ff0000"
    readonly property color tooltip: "#1e1e2e"

    // waybar max-length: cut to `max` characters, the last one becoming an ellipsis.
    function elide(text: string, max: int): string {
        const chars = Array.from(text);
        return chars.length > max ? chars.slice(0, max - 1).join("") + "…" : text;
    }
}
