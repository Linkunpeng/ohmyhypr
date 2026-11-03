import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import "../services"

Rectangle {
    id: root
    required property string kind
    required property string screenName
    readonly property var device: kind === "wifi" ? Connectivity.wifi : Connectivity.bluetooth
    readonly property bool powered: device.available && device.enabled
    readonly property bool connected: kind === "wifi" ? !!device.connected : (device.devices || []).some(d => d.connected)
    implicitWidth: content.implicitWidth + 12
    implicitHeight: 26
    radius: Theme.widgetCorner(height)
    color: hover.containsMouse || Connectivity.openMenu === kind ? Theme.withAlpha(Theme.accent, 0.22) : "transparent"
    ToolTip.visible: hover.containsMouse
    ToolTip.delay: 600
    ToolTip.text: !device.available ? (kind === "wifi" ? "Wi-Fi unavailable" : "Bluetooth unavailable") :
                  !device.enabled ? "Off" : kind === "wifi" ? (device.connected || "Not connected") :
                  (connected ? "Connected" : "On")
    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: 5
        Rectangle {
            implicitWidth: 7; implicitHeight: 7; radius: 4
            color: !root.device.available ? Theme.urgent : root.connected ? Theme.accent : root.powered ? Theme.muted : Theme.urgent
            opacity: root.device.available && !root.powered ? 0.55 : 1
        }
        Item {
            implicitWidth: 20
            implicitHeight: 20
            Image {
                id: glyph
                anchors.fill: parent
                source: "file://" + (Quickshell.shellDir + "/assets/icons/" + (root.kind === "wifi" ? "wifi.png" : "bluetooth.png")).split("/").map(encodeURIComponent).join("/")
                sourceSize: Qt.size(80, 80)
                fillMode: Image.PreserveAspectFit
                smooth: true
                visible: false
            }
            ColorOverlay {
                anchors.fill: glyph
                source: glyph
                color: root.powered ? Theme.fg : Theme.muted
            }
        }
    }
    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Connectivity.toggleMenu(root.kind, root.screenName)
    }
}
