import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services"

// Shape follows the theme: floating (inset, rounded) or docked (edge to edge),
// top or bottom.
PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    readonly property int inset: Theme.barFloating ? Theme.gap : 0

    anchors {
        top: !Theme.barBottom
        bottom: Theme.barBottom
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight + inset
    color: "transparent"
    WlrLayershell.namespace: "omh-bar"

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: Theme.barBottom ? 0 : bar.inset
        anchors.bottomMargin: Theme.barBottom ? bar.inset : 0
        anchors.leftMargin: bar.inset
        anchors.rightMargin: bar.inset
        radius: Theme.barFloating ? Theme.radius : 0
        color: Theme.bg

        // docked bars get a hairline in the accent color on the inner edge
        Rectangle {
            visible: !Theme.barFloating
            anchors.left: parent.left
            anchors.right: parent.right
            y: Theme.barBottom ? 0 : parent.height - height
            height: 1
            color: Theme.withAlpha(Theme.accent, 0.6)
        }

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

            ThemeButton {}

            AskButton {}
        }
    }
}
