import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services"

PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight + Theme.gap
    color: "transparent"
    WlrLayershell.namespace: "omh-bar"

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: Theme.gap
        anchors.leftMargin: Theme.gap
        anchors.rightMargin: Theme.gap
        radius: Theme.radius
        color: Theme.bg

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 8

            Workspaces {
                screen: bar.screen
            }

            Item { Layout.fillWidth: true }

            Clock {}

            Item { Layout.fillWidth: true }

            AskButton {}
        }
    }
}
