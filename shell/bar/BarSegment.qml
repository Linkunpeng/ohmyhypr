import QtQuick
import QtQuick.Shapes
import "../services"

// waybar `.modules-left/center/right`: half-transparent black box with 15px corners
// and a 2px bottom border that thins out around the lower corners.
Item {
    id: segment
    default property alias content: row.data
    implicitWidth: row.implicitWidth + 8
    implicitHeight: BarStyle.boxHeight

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: -1
            fillColor: BarStyle.background
            PathRectangle { width: segment.width; height: segment.height; radius: BarStyle.radius }
        }
        ShapePath {
            id: border
            readonly property real w: segment.width
            readonly property real h: segment.height
            readonly property int r: BarStyle.radius
            strokeWidth: -1
            fillColor: BarStyle.border
            // Outer bottom corners (r) minus the padding box's corners (r - 2, raised by 2).
            PathSvg {
                path: `M 0 ${border.h - border.r} A ${border.r} ${border.r} 0 0 0 ${border.r} ${border.h}`
                    + ` L ${border.w - border.r} ${border.h} A ${border.r} ${border.r} 0 0 0 ${border.w} ${border.h - border.r}`
                    + ` A ${border.r - 2} ${border.r - 2} 0 0 1 ${border.w - border.r + 2} ${border.h - 2}`
                    + ` L ${border.r - 2} ${border.h - 2} A ${border.r - 2} ${border.r - 2} 0 0 1 0 ${border.h - border.r} Z`
            }
        }
    }

    Row {
        id: row
        x: 4
        y: 2
        spacing: BarStyle.spacing
    }
}
