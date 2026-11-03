import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"

// Layer-shell host for BarContent; the transparent space between its three
// boxes passes pointer input through.
PanelWindow {
    id: bar
    required property var modelData
    screen: modelData
    visible: !Omh.barHidden

    anchors {
        top: !Theme.barBottom
        bottom: Theme.barBottom
        left: true
        right: true
    }
    implicitHeight: BarStyle.marginTop + BarStyle.boxHeight
    exclusiveZone: implicitHeight
    color: "transparent"
    WlrLayershell.namespace: "omh-bar"
    mask: Region {
        item: content.leftBox
        Region { item: content.centerBox }
        Region { item: content.rightBox }
    }

    IdleInhibitor {
        window: bar
        enabled: Omh.idleInhibited
    }

    BarContent {
        id: content
        anchors.fill: parent
        screen: bar.screen
    }
}
