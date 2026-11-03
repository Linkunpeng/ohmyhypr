import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services"

PanelWindow {
    id: panel
    required property var modelData
    readonly property bool wifiMode: Connectivity.openMenu === "wifi"
    readonly property var device: wifiMode ? Connectivity.wifi : Connectivity.bluetooth
    screen: modelData
    visible: Connectivity.openMenu !== "" && (Connectivity.targetScreen ? modelData.name === Connectivity.targetScreen : modelData === Quickshell.screens[0])
    anchors { top: !Theme.barBottom; bottom: Theme.barBottom; right: true }
    readonly property int barOffset: BarStyle.marginTop + BarStyle.boxHeight + 8
    margins { top: !Theme.barBottom ? barOffset : 0; bottom: Theme.barBottom ? barOffset : 0; right: BarStyle.marginSide }
    implicitWidth: Math.min(400, screen ? screen.width - 24 : 400)
    implicitHeight: Math.min(490, screen ? screen.height - 90 : 490)
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "omh-connectivity"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    onVisibleChanged: if (visible) focusTarget.forceActiveFocus()

    Rectangle {
        anchors.fill: parent
        anchors.margins: 4
        radius: Math.max(10, Theme.radius)
        color: Theme.bgSolid
        border.width: 1
        border.color: Theme.withAlpha(Theme.accent, 0.8)
        Item { id: focusTarget; focus: true; Keys.onEscapePressed: Connectivity.openMenu = "" }
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12
            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: panel.wifiMode ? "Wi-Fi" : "Bluetooth"
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: 20
                    font.bold: true
                }
                ActionButton {
                    label: !panel.device.available ? "Unavailable" : panel.device.enabled ? "Turn off" : "Turn on"
                    enabled: panel.device.available && !Connectivity.busy
                    onClicked: Connectivity.run(Connectivity.openMenu, panel.device.enabled ? "off" : "on", "")
                }
                ActionButton { label: "×"; onClicked: Connectivity.openMenu = "" }
            }
            Text {
                Layout.fillWidth: true
                text: !panel.device.available ? (panel.wifiMode ? "iwd or a Wi-Fi adapter is unavailable" : "Bluetooth service or adapter is unavailable") :
                      !panel.device.enabled ? "Off" : panel.wifiMode ? (panel.device.connected ? "Connected · " + panel.device.connected : "Not connected") :
                      ((panel.device.devices || []).some(d => d.connected) ? "Connected" : "On · not connected")
                textFormat: Text.PlainText
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 12
                elide: Text.ElideRight
            }
            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.withAlpha(Theme.accent, 0.35) }
            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: panel.wifiMode ? "Available networks" : "Devices"
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: 13
                    font.bold: true
                }
                ActionButton {
                    label: Connectivity.busy ? "Working…" : "Scan"
                    enabled: panel.device.available && panel.device.enabled && !Connectivity.busy
                    onClicked: Connectivity.run(Connectivity.openMenu, "scan", "")
                }
            }
            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 6
                model: !panel.device.enabled ? [] : panel.wifiMode ? (panel.device.networks || []) : (panel.device.devices || [])
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                delegate: Rectangle {
                    id: card
                    required property var modelData
                    width: list.width
                    height: 54
                    radius: 8
                    color: Theme.surface
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                Layout.fillWidth: true
                                text: card.modelData.name
                                textFormat: Text.PlainText
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: 13
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: panel.wifiMode ? (card.modelData.connected ? "Connected" : card.modelData.known ? "Saved" : "New network") +
                                      " · " + (card.modelData.security || "unknown") + (card.modelData.signal === null || card.modelData.signal === undefined ? "" : " · " + card.modelData.signal + " dBm") :
                                      card.modelData.connected ? "Connected" : card.modelData.paired ? "Paired" : "Available"
                                textFormat: Text.PlainText
                                color: Theme.muted
                                font.family: Theme.font
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                        }
                        ActionButton {
                            label: card.modelData.connected ? "Disconnect" : panel.wifiMode ? "Connect" : card.modelData.paired ? "Connect" : "Pair"
                            enabled: !Connectivity.busy
                            onClicked: {
                                const entry = card.modelData;
                                if (panel.wifiMode) {
                                    if (entry.connected) Connectivity.run("wifi", "disconnect", "");
                                    else if (entry.known || entry.security === "open") Connectivity.run("wifi", "connect", entry.path);
                                    else {
                                        const args = ["iwctl", "station", Connectivity.wifi.interface, "connect", entry.name];
                                        if (entry.security) args.push(entry.security);
                                        Connectivity.openTerminal(args);
                                    }
                                } else if (entry.connected || entry.paired) {
                                    Connectivity.run("bluetooth", entry.connected ? "disconnect" : "connect", entry.path);
                                } else {
                                    Connectivity.openTerminal(["bluetoothctl", "--agent", "KeyboardDisplay", "pair", entry.address]);
                                }
                            }
                        }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    text: !panel.device.available ? "No adapter" : !panel.device.enabled ? "Turn on to see devices" : panel.wifiMode ? "No networks found · try Scan" : "No devices found · try Scan"
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 12
                }
            }
            Text {
                Layout.fillWidth: true
                visible: Connectivity.error !== ""
                text: Connectivity.error
                textFormat: Text.PlainText
                color: Theme.urgent
                font.family: Theme.font
                font.pixelSize: 11
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: panel.wifiMode ? "New secured networks open a terminal for credentials." : "Pairing prompts open in a terminal."
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 11
                wrapMode: Text.Wrap
            }
        }
    }
}
