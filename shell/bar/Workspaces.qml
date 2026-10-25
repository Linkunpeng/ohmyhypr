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

            visible: modelData.id > 0 && modelData.monitor === root.monitor
            implicitWidth: active ? 28 : 18
            implicitHeight: 18
            radius: 9
            color: active ? Theme.accent : Theme.surface

            Behavior on implicitWidth { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

            Text {
                anchors.centerIn: parent
                text: ws.modelData.name
                color: ws.active ? Theme.bg : Theme.muted
                font.family: Theme.font
                font.pixelSize: 10
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Omh.focusWorkspace(ws.modelData.id)
            }
        }
    }
}
