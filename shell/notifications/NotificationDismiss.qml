import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"

PanelWindow {
    required property var modelData
    screen: modelData
    visible: NotificationStore.centerOpen
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "omh-notification-dismiss"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    MouseArea {
        anchors.fill: parent
        onClicked: NotificationStore.centerOpen = false
    }
}
