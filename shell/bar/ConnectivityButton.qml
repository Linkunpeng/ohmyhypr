import QtQuick
import QtQuick.Controls
import "../services"

Rectangle {
    id: root
    required property string kind
    required property string screenName
    readonly property var device: kind === "wifi" ? Connectivity.wifi : Connectivity.bluetooth
    readonly property bool powered: device.available && device.enabled
    readonly property bool connected: kind === "wifi" ? !!device.connected : (device.devices || []).some(d => d.connected)
    implicitWidth: Math.max(implicitHeight, content.implicitWidth + 10)
    implicitHeight: 26
    radius: Theme.softCorner(height)
    color: hover.containsMouse || Connectivity.openMenu === kind ? Theme.withAlpha(Theme.accent, 0.22) : "transparent"
    ToolTip.visible: hover.containsMouse
    ToolTip.delay: 600
    ToolTip.text: !device.available ? (kind === "wifi" ? "Wi-Fi unavailable" : "Bluetooth unavailable") :
                  !device.enabled ? "Off" : kind === "wifi" ? (device.connected || "Not connected") :
                  (connected ? "Connected" : "On")
    // Nerd Font (Material) glyphs: Wi-Fi shows signal strength, Bluetooth shows link state.
    readonly property int signal: {
        const net = kind === "wifi" ? (device.networks || []).find(n => n.connected) : null;
        return net && net.signal !== null && net.signal !== undefined ? net.signal : -60;
    }
    readonly property string glyph: kind === "wifi"
        ? (!device.available ? "\udb82\udd2b" : !powered ? "\udb82\udd2e" : !connected ? "\udb82\udd2f"
           : signal >= -55 ? "\udb82\udd28" : signal >= -67 ? "\udb82\udd25" : signal >= -75 ? "\udb82\udd22" : "\udb82\udd1f")
        : (!device.available || !powered ? "\udb80\udcb2" : connected ? "\udb80\udcb1" : "\udb80\udcaf")
    Text {
        id: content
        anchors.centerIn: parent
        text: root.glyph
        color: !root.device.available ? Theme.urgent : root.connected ? Theme.accent : root.powered ? Theme.fg : Theme.muted
        opacity: root.device.available && !root.powered ? 0.6 : 1
        font.family: Theme.monoFont
        font.pixelSize: Theme.fontSize + 5
        Behavior on color { ColorAnimation { duration: 200 } }
    }
    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Connectivity.toggleMenu(root.kind, root.screenName)
    }
}
