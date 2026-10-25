import QtQuick
import "../services"

// Opens the theme picker; shows the current theme name.
Rectangle {
    implicitWidth: label.implicitWidth + 20
    implicitHeight: 24
    radius: Theme.widgetCorner(height)
    color: hover.containsMouse ? Theme.withAlpha(Theme.accent, 0.25) : Theme.surface

    Text {
        id: label
        anchors.centerIn: parent
        text: "◐ " + Theme.name
        color: Theme.fg
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 1
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Omh.themePickerOpen = !Omh.themePickerOpen
    }
}
