import QtQuick
import Quickshell.Hyprland
import "../services"
import "windowicons.js" as WindowIcons

// waybar `hyprland/workspaces#rw`: workspaces of every output plus five persistent
// ones per monitor, each labelled with its number and a glyph per window.
Rectangle {
    id: root
    property HyprlandMonitor monitor

    readonly property var ids: {
        const base = (monitor?.id ?? 0) * 5;
        const ids = new Set([1, 2, 3, 4, 5].map(i => base + i));
        for (const ws of Hyprland.workspaces.values)
            if (ws.id > 0)
                ids.add(ws.id);
        return [...ids].sort((a, b) => a - b);
    }
    readonly property var glyphs: {
        const byWorkspace = {};
        for (const window of Hyprland.toplevels.values) {
            const id = window.workspace?.id ?? 0;
            if (id <= 0)
                continue;
            const cls = window.wayland?.appId || window.lastIpcObject?.class || "";
            (byWorkspace[id] = byWorkspace[id] || []).push(WindowIcons.glyphFor(cls, window.title));
        }
        return byWorkspace;
    }

    implicitWidth: row.implicitWidth + 6
    implicitHeight: BarStyle.moduleHeight
    radius: BarStyle.radius
    color: "transparent"
    border.width: 2
    border.color: BarStyle.border
    opacity: 0.8

    Row {
        id: row
        anchors.centerIn: parent

        Repeater {
            model: root.ids

            delegate: Item {
                id: button
                required property int modelData
                readonly property bool active: Hyprland.focusedWorkspace?.id === modelData
                readonly property bool urgent: Hyprland.workspaces.values.some(ws => ws.id === modelData && ws.urgent)
                // CSS order in waybar: :hover overrides .active padding.
                property real padding: mouse.containsMouse ? 2 : active ? 8 : 4

                // GTK buttons keep a 1px margin on each side.
                implicitWidth: label.implicitWidth + padding * 2 + 2
                implicitHeight: BarStyle.moduleHeight - 4
                Behavior on padding {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.55, -0.68, 0.48, 1.682, 1, 1]
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: 1
                    anchors.rightMargin: 1
                    radius: mouse.containsMouse ? 10 : height / 2
                    color: "black"
                    visible: button.active
                }

                Text {
                    id: label
                    anchors.centerIn: parent
                    text: button.modelData + " " + (root.glyphs[button.modelData] ?? []).join(" ")
                    color: button.active || mouse.containsMouse ? BarStyle.gold : button.urgent ? "#11111b" : BarStyle.inactive
                    font.family: BarStyle.font
                    font.pixelSize: BarStyle.fontSize
                    font.bold: true
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Omh.focusWorkspace(button.modelData)
                }
            }
        }
    }
}
