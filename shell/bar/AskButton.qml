import QtQuick
import "../services"

// Bar entry to the omnibox; later also shows agent / model activity.
Rectangle {
    implicitWidth: label.implicitWidth + 20
    implicitHeight: 24
    radius: Theme.widgetCorner(height)
    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0; color: Theme.accent }
        GradientStop { position: 1; color: Theme.accentAlt }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: "✦ Ask"
        color: Theme.bg
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        font.bold: true
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Omh.omniboxOpen = !Omh.omniboxOpen
    }
}
