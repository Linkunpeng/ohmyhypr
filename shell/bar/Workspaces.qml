import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../services"

RowLayout {
    id: root

    property ShellScreen screen
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)

    spacing: 4

    Repeater {
        model: Hyprland.workspaces

        delegate: Rectangle {
            id: ws

            required property HyprlandWorkspace modelData
            readonly property bool active: root.monitor?.activeWorkspace?.id === modelData.id
            readonly property bool urgent: modelData.urgent && !active
            readonly property bool hovered: pointer.containsMouse

            visible: modelData.id > 0 && modelData.monitor === root.monitor
            implicitWidth: active ? 28 : 18
            implicitHeight: 18
            radius: Theme.softCorner(height)
            color: active ? Theme.accent
                : urgent ? Theme.withAlpha(Theme.urgent, 0.35)
                : hovered ? Theme.withAlpha(Theme.accent, 0.3)
                : Theme.surface
            border.width: active ? 0 : 1
            border.color: urgent ? Theme.urgent : Theme.withAlpha(Theme.accent, hovered ? 0.55 : 0.18)
            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on border.color { ColorAnimation { duration: 200 } }
            Behavior on implicitWidth { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

            // Soft highlight on the active chip so it reads as raised.
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                visible: ws.active
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.22) }
                    GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
                }
            }

            Text {
                anchors.centerIn: parent
                text: ws.modelData.name
                color: ws.active ? Theme.bgSolid : ws.urgent || ws.hovered ? Theme.fg : Theme.muted
                font.family: Theme.font
                font.pixelSize: 10
                font.bold: ws.active
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            MouseArea {
                id: pointer
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Omh.focusWorkspace(ws.modelData.id)
            }
        }
    }
}
