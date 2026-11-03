import QtQuick
import "../services"

Rectangle {
    id: root
    property string label: ""
    signal clicked()
    implicitWidth: title.implicitWidth + 20
    implicitHeight: 30
    radius: 7
    opacity: enabled ? 1 : 0.45
    color: pointer.containsMouse && enabled ? Theme.withAlpha(Theme.accent, 0.3) : Theme.surface
    border.width: 1
    border.color: Theme.withAlpha(Theme.accent, 0.5)
    Text {
        id: title
        anchors.centerIn: parent
        text: root.label
        color: Theme.fg
        font.family: Theme.font
        font.pixelSize: 12
    }
    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (root.enabled) root.clicked()
    }
}
