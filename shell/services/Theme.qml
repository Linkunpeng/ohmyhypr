pragma Singleton

// Live theme: mirrors $XDG_STATE_HOME/ohmyhypr/theme.json (written by
// `omh theme apply`). Colors animate when the theme changes.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string statePath: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/ohmyhypr/theme.json"

    property var data: ({})
    readonly property var palette: data.palette ?? ({})
    readonly property var shape: data.shape ?? ({})
    readonly property var fontSpec: data.font ?? ({})

    readonly property string id: data.id ?? "builtin"
    readonly property string name: data.meta?.name ?? "Builtin"
    readonly property bool dark: data.meta?.dark ?? true
    readonly property string wallpaper: data.wallpaper?.path ?? ""
    readonly property string wallpaperFit: data.wallpaper?.fit ?? "cover"

    property color bg: withAlpha(palette.bg ?? "#181926", palette.opacity ?? 0.78)
    property color bgSolid: palette.bg ?? "#181926"
    property color surface: withAlpha(palette.surface ?? "#24273a", 0.9)
    property color fg: palette.fg ?? "#cad3f5"
    property color muted: palette.muted ?? "#6e738d"
    property color accent: palette.accent ?? "#8aadf4"
    property color accentAlt: palette.accent_alt ?? "#c6a0f6"
    property color urgent: palette.urgent ?? "#ed8796"

    Behavior on bg { ColorAnimation { duration: 450 } }
    Behavior on bgSolid { ColorAnimation { duration: 450 } }
    Behavior on surface { ColorAnimation { duration: 450 } }
    Behavior on fg { ColorAnimation { duration: 450 } }
    Behavior on muted { ColorAnimation { duration: 450 } }
    Behavior on accent { ColorAnimation { duration: 450 } }
    Behavior on accentAlt { ColorAnimation { duration: 450 } }

    readonly property int radius: shape.radius ?? 12
    readonly property bool barFloating: (shape.bar ?? "floating") === "floating"
    readonly property bool barBottom: (shape.bar_position ?? "top") === "bottom"
    readonly property int gap: shape.gaps_out ?? 10

    readonly property string font: fontSpec.ui ?? "Inter"
    readonly property string monoFont: fontSpec.mono ?? "JetBrainsMono Nerd Font"
    readonly property int fontSize: fontSpec.size ?? 13

    function withAlpha(c: string, a: real): color {
        const q = Qt.color(c);
        return Qt.rgba(q.r, q.g, q.b, a);
    }

    FileView {
        path: root.statePath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.data = JSON.parse(text());
            } catch (e) {
                console.warn("theme.json:", e);
            }
        }
    }
}
