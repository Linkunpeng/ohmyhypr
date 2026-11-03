import QtQuick
import Quickshell
import "../services"

// waybar tooltip: dark card, 12px corners, 1px border in the bar's border color.
PopupWindow {
    id: root
    required property Item target
    property string text
    property int textFormat: Text.PlainText

    anchor.item: target
    anchor.edges: Theme.barBottom ? Edges.Top : Edges.Bottom
    anchor.gravity: Theme.barBottom ? Edges.Top : Edges.Bottom
    anchor.margins.top: Theme.barBottom ? 0 : 6
    anchor.margins.bottom: Theme.barBottom ? 6 : 0
    implicitWidth: card.width
    implicitHeight: card.height
    color: "transparent"
    visible: false

    Timer {
        running: true
        interval: 500
        onTriggered: root.visible = true
    }

    Rectangle {
        id: card
        width: label.implicitWidth + 20
        height: label.implicitHeight + 14
        radius: 12
        color: BarStyle.tooltip
        border.width: 1
        border.color: BarStyle.border
        Text {
            id: label
            anchors.centerIn: parent
            text: root.text
            textFormat: root.textFormat
            color: "#ffffff"
            font.family: BarStyle.font
            font.pixelSize: BarStyle.fontSize
            font.bold: true
        }
    }
}
