import QtQuick
import Quickshell
import "../services"

Rectangle {
    id: root
    required property string screenName
    property real pulse: 0
    implicitWidth: Math.min(320, label.implicitWidth + 22)
    implicitHeight: 26
    radius: Theme.widgetCorner(height)
    color: NotificationMonitor.recent ? Theme.withAlpha(Theme.accent, 0.28 + pulse * 0.25) : hover.containsMouse ? Theme.withAlpha(Theme.accent, 0.25) : "transparent"
    border.width: NotificationMonitor.recent ? 2 : 0
    border.color: Theme.accent
    Behavior on implicitWidth { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    SequentialAnimation on pulse {
        running: NotificationMonitor.recent
        loops: Animation.Infinite
        NumberAnimation { from: 0; to: 1; duration: 550; easing.type: Easing.InOutSine }
        NumberAnimation { from: 1; to: 0; duration: 550; easing.type: Easing.InOutSine }
    }

    Text {
        id: label
        anchors.centerIn: parent
        width: Math.min(implicitWidth, root.width - 22)
        elide: Text.ElideRight
        text: NotificationMonitor.recent ? "🔔  " + (NotificationMonitor.preview || "New notification") : "🔔 Notifications"
        textFormat: Text.PlainText
        color: Theme.fg
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        font.bold: NotificationMonitor.recent
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            NotificationMonitor.dismissHint();
            Quickshell.execDetached([Omh.repo + "scripts/notification-center.sh", screenName]);
        }
    }
}
