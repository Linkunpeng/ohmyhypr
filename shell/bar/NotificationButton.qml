import QtQuick
import "../services"

Rectangle {
    id: root
    required property string screenName
    property real pulse: 0
    implicitWidth: Math.min(320, label.implicitWidth + 22)
    implicitHeight: 26
    radius: Theme.softCorner(height)
    color: NotificationStore.recent ? Theme.withAlpha(Theme.accent, 0.22 + pulse * 0.2) : hover.containsMouse ? Theme.withAlpha(Theme.accent, 0.22) : "transparent"
    border.width: NotificationStore.recent || hover.containsMouse ? 1.5 : 0
    border.color: Theme.withAlpha(Theme.accent, NotificationStore.recent ? 0.7 + pulse * 0.3 : 0.45)
    antialiasing: true
    Behavior on implicitWidth { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    SequentialAnimation on pulse {
        running: NotificationStore.recent
        loops: Animation.Infinite
        NumberAnimation { from: 0; to: 1; duration: 550; easing.type: Easing.InOutSine }
        NumberAnimation { from: 1; to: 0; duration: 550; easing.type: Easing.InOutSine }
    }

    Text {
        id: label
        anchors.centerIn: parent
        width: Math.min(implicitWidth, root.width - 22)
        elide: Text.ElideRight
        text: NotificationStore.recent ? "\uf0f3  " + (NotificationStore.preview || "New notification") : "\uf0f3  Notifications"
        textFormat: Text.PlainText
        color: Theme.fg
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        font.bold: NotificationStore.recent
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            NotificationStore.dismissHint();
            NotificationStore.toggle(screenName);
        }
    }
}
