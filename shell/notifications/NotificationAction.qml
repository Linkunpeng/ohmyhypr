import QtQuick
import QtQuick.Shapes

Item {
    id: button
    property alias text: label.text
    required property color foreground
    required property color background
    required property color accent
    required property string fontFamily
    signal clicked()
    implicitWidth: label.implicitWidth + 18
    implicitHeight: 26
    property color fillColor: pointer.containsMouse ? accent : background
    Behavior on fillColor { ColorAnimation { duration: 150 } }

    Shape {
        anchors.fill: parent
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: -1
            fillColor: button.fillColor
            PathRectangle { width: button.width; height: button.height; radius: button.height / 2 }
        }
        ShapePath {
            strokeWidth: -1
            fillColor: button.accent
            fillRule: ShapePath.OddEvenFill
            PathRectangle { width: button.width; height: button.height; radius: button.height / 2 }
            PathRectangle {
                x: 2; y: 2
                width: Math.max(0, button.width - 4); height: Math.max(0, button.height - 4)
                radius: Math.max(0, button.height / 2 - 2)
            }
        }
    }
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
