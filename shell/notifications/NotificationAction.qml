import QtQuick

Rectangle {
    id: button
    property alias text: label.text
    required property color foreground
    required property color background
    required property color accent
    required property string fontFamily
    signal clicked()
    implicitWidth: label.implicitWidth + 18
    implicitHeight: 26
    radius: 6
    color: pointer.containsMouse ? accent : background
    border.width: 1
    border.color: accent
    Text {
        id: label
        anchors.centerIn: parent
        color: pointer.containsMouse ? button.background : button.foreground
        font.family: button.fontFamily
        font.pixelSize: 11
    }
    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
    }
}
