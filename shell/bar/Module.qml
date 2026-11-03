import QtQuick
import "../services"

// One waybar module: bold Nerd Font label with 6px side padding; empty text hides it.
Item {
    id: root
    property string text
    property color color: BarStyle.text
    property int textFormat: Text.PlainText
    property int padding: BarStyle.padding
    property int chars: 0              // waybar min-length: fixed width, text centered
    property string tooltip
    property int tooltipFormat: Text.PlainText
    readonly property alias hovered: mouse.containsMouse
    signal clicked(int button)
    signal scrolled(int steps)         // +1 up, -1 down

    visible: text !== ""
    implicitWidth: Math.max(label.implicitWidth, chars > 0 ? metrics.advanceWidth : 0) + padding * 2
    implicitHeight: BarStyle.moduleHeight

    TextMetrics {
        id: metrics
        font: label.font
        text: "0".repeat(root.chars)
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        textFormat: root.textFormat
        color: root.color
        font.family: BarStyle.font
        font.pixelSize: BarStyle.fontSize
        font.bold: true
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: event => root.clicked(event.button)
        onWheel: event => {
            if (event.angleDelta.y !== 0)
                root.scrolled(event.angleDelta.y > 0 ? 1 : -1);
        }
    }

    Loader {
        active: root.tooltip !== "" && mouse.containsMouse
        sourceComponent: BarTooltip {
            target: root
            text: root.tooltip
            textFormat: root.tooltipFormat
        }
    }
}
