pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property color bg: Qt.rgba(0.09, 0.10, 0.14, 0.72)
    readonly property color surface: Qt.rgba(1, 1, 1, 0.06)
    readonly property color fg: "#cad3f5"
    readonly property color muted: "#6e738d"
    readonly property color accent: "#8aadf4"
    readonly property color accentAlt: "#c6a0f6"

    readonly property int radius: 12
    readonly property int barHeight: 34
    readonly property int gap: 10

    readonly property string font: "Inter"
    readonly property string monoFont: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 13
}
