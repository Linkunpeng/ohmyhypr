import QtQuick
import "../services"

// Monochrome Nerd Font glyph + value; tinted glyph, plain text.
Row {
    property string glyph
    property string value
    property color tint: Theme.accent
    property color textColor: Theme.fg
    spacing: 5
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: parent.glyph
        color: parent.tint
        font.family: Theme.monoFont
        font.pixelSize: Theme.fontSize + 1
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: parent.value
        color: parent.textColor
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        font.features: { "tnum": 1 }
    }
}
