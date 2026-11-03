import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services"

// Three independent segments; transparent gaps pass pointer input through.
PanelWindow {
    id: bar
    required property var modelData
    screen: modelData
    visible: !Omh.barHidden

    readonly property int inset: Math.max(8, Theme.gap)
    readonly property int segmentHeight: Math.max(36, Theme.barHeight)
    readonly property int segmentY: Theme.barBottom ? 0 : inset

    anchors {
        top: !Theme.barBottom
        bottom: Theme.barBottom
        left: true
        right: true
    }
    implicitHeight: segmentHeight + inset
    exclusiveZone: implicitHeight
    color: "transparent"
    WlrLayershell.namespace: "omh-bar"
    mask: Region {
        item: leftSegment
        Region { item: centerSegment }
        Region { item: rightSegment }
    }

    BarSegment {
        id: leftSegment
        x: bar.inset
        y: bar.segmentY
        width: workspaces.implicitWidth + 28
        height: bar.segmentHeight
        Workspaces {
            id: workspaces
            anchors.centerIn: parent
            screen: bar.screen
        }
    }

    BarSegment {
        id: centerSegment
        anchors.horizontalCenter: parent.horizontalCenter
        y: bar.segmentY
        width: clock.implicitWidth + 32
        height: bar.segmentHeight
        Clock {
            id: clock
            anchors.centerIn: parent
        }
    }

    BarSegment {
        id: rightSegment
        anchors.right: parent.right
        anchors.rightMargin: bar.inset
        y: bar.segmentY
        width: statusRow.implicitWidth + 28
        height: bar.segmentHeight
        RowLayout {
            id: statusRow
            anchors.centerIn: parent
            spacing: 16
            SystemStatus {}
            Rectangle {
                visible: tray.itemCount > 0
                width: 1
                height: 18
                color: Theme.withAlpha(Theme.accent, 0.45)
            }
            Tray { id: tray }
        }
    }
}
