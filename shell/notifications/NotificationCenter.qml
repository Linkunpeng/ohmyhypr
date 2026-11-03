import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../services"

PanelWindow {
    id: panel
    required property var modelData
    screen: modelData
    visible: NotificationStore.centerOpen && (NotificationStore.targetScreen
        ? modelData.name === NotificationStore.targetScreen : modelData === Quickshell.screens[0])
    anchors { top: true }
    margins { top: 60 }
    implicitWidth: Math.min(448, screen ? screen.width - 36 : 448)
    implicitHeight: Math.min(500, screen ? screen.height - 110 : 500)
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "omh-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    property var appearance: ({})
    readonly property var palette: appearance.palette ?? ({})
    readonly property color background: palette.bg ?? "#181926"
    readonly property color surface: palette.surface ?? "#24273a"
    readonly property color foreground: palette.fg ?? "#cad3f5"
    readonly property color muted: palette.muted ?? "#6e738d"
    readonly property color accent: palette.accent ?? "#8aadf4"
    readonly property string fontFamily: appearance.font?.ui ?? "Noto Sans CJK SC"
    readonly property int cornerRadius: Math.max(8, appearance.shape?.radius ?? 12)

    FileView {
        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/ohmyhypr/theme.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try { panel.appearance = JSON.parse(text()); }
            catch (e) { console.warn("notification theme:", e); }
        }
    }

    Rectangle {
        id: glass
        anchors.fill: parent
        anchors.margins: 6
        radius: panel.cornerRadius
        color: Qt.rgba(panel.background.r, panel.background.g, panel.background.b, panel.palette.opacity ?? 0.9)
        border.width: 1
        border.color: panel.accent
        focus: true
        Keys.onEscapePressed: NotificationStore.centerOpen = false

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14
            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "Notifications"
                    color: panel.foreground
                    font.family: panel.fontFamily
                    font.pixelSize: 20
                    font.bold: true
                }
                Text {
                    text: NotificationStore.items.length.toString()
                    color: panel.muted
                    font.family: panel.fontFamily
                    font.pixelSize: 13
                }
                NotificationAction {
                    text: "Clear all"
                    foreground: panel.foreground; background: panel.background; accent: panel.accent; fontFamily: panel.fontFamily
                    visible: NotificationStore.items.length > 0
                    onClicked: NotificationStore.clear()
                }
                Rectangle {
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 6
                    color: closeArea.containsMouse ? panel.surface : "transparent"
                    Text { anchors.centerIn: parent; text: "×"; color: panel.foreground; font.pixelSize: 22 }
                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotificationStore.centerOpen = false
                    }
                }
            }
            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: panel.accent; opacity: 0.4 }
            ListView {
                id: noticeList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 8
                model: NotificationStore.items
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                delegate: Rectangle {
                    id: card
                    required property var modelData
                    property bool expanded: false
                    width: noticeList.width
                    height: content.implicitHeight + 24
                    radius: panel.cornerRadius
                    color: panel.surface
                    border.width: 1
                    border.color: Qt.rgba(panel.accent.r, panel.accent.g, panel.accent.b, 0.3)
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.expanded = !card.expanded
                    }
                    Column {
                        id: content
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                        spacing: 6
                        RowLayout {
                            width: parent.width
                            Text {
                                Layout.fillWidth: true
                                text: card.modelData.app || "Notification"
                                textFormat: Text.PlainText
                                color: panel.accent
                                font.family: panel.fontFamily
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                            Text {
                                text: Qt.formatTime(new Date(card.modelData.time * 1000), "HH:mm")
                                color: panel.muted
                                font.family: panel.fontFamily
                                font.pixelSize: 11
                            }
                        }
                        Text {
                            width: parent.width
                            visible: text.length > 0
                            text: card.modelData.title || ""
                            textFormat: Text.PlainText
                            wrapMode: Text.Wrap
                            color: panel.foreground
                            font.family: panel.fontFamily
                            font.pixelSize: 14
                            font.bold: true
                        }
                        Text {
                            width: parent.width
                            visible: text.length > 0
                            text: card.modelData.body || ""
                            textFormat: Text.PlainText
                            wrapMode: Text.Wrap
                            maximumLineCount: card.expanded ? 2147483647 : 3
                            elide: Text.ElideRight
                            color: panel.muted
                            font.family: panel.fontFamily
                            font.pixelSize: 12
                        }
                        Text {
                            visible: !!card.modelData.body
                            text: card.expanded ? "Show less" : "Show details"
                            color: panel.accent
                            font.family: panel.fontFamily
                            font.pixelSize: 11
                        }
                        Flow {
                            width: parent.width
                            spacing: 6
                            Repeater {
                                model: card.modelData.live ? card.modelData.actions : []
                                delegate: NotificationAction {
                                    foreground: panel.foreground; background: panel.background; accent: panel.accent; fontFamily: panel.fontFamily
                                    required property string modelData
                                    required property int index
                                    text: modelData
                                    onClicked: NotificationStore.invoke(card.modelData.id, index)
                                }
                            }
                            NotificationAction { foreground: panel.foreground; background: panel.background; accent: panel.accent; fontFamily: panel.fontFamily; text: "Remove"; onClicked: NotificationStore.remove(card.modelData.id) }
                        }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    visible: noticeList.count === 0
                    text: "No notifications yet"
                    color: panel.muted
                    font.family: panel.fontFamily
                    font.pixelSize: 14
                }
            }
        }
    }
}
