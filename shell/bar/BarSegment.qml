import QtQuick
import QtQuick.Shapes
import "../services"

Rectangle {
    id: segment
    property real borderAngle: 0
    readonly property color borderAccent: complement(Theme.accent)
    readonly property color borderAccentAlt: complement(Theme.accentAlt)

    function complement(c: color): color {
        const hue = c.hsvHue < 0 ? 0 : c.hsvHue;
        return Qt.hsva((hue + 0.5) % 1, Math.min(c.hsvSaturation, 0.24), Math.min(c.hsvValue * 1.1, 1), 1);
    }

    radius: height / 2
    // The wallpaper palette raises opacity only as needed for readable text.
    color: Qt.rgba(Theme.bgSolid.r, Theme.bgSolid.g, Theme.bgSolid.b, Theme.palette.bar_opacity ?? 0.38)

    Shape {
        anchors.fill: parent
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer
        z: 1
        ShapePath {
            strokeWidth: -1
            fillRule: ShapePath.OddEvenFill
            fillGradient: ConicalGradient {
                centerX: segment.width / 2
                centerY: segment.height / 2
                angle: segment.borderAngle
                GradientStop { position: 0.0; color: Theme.withAlpha(segment.borderAccent, 0.65) }
                GradientStop { position: 0.12; color: Qt.lighter(segment.borderAccent, 1.25) }
                GradientStop { position: 0.26; color: Theme.withAlpha(segment.borderAccentAlt, 0.8) }
                GradientStop { position: 0.55; color: Theme.withAlpha(segment.borderAccent, 0.65) }
                GradientStop { position: 0.78; color: Theme.withAlpha(segment.borderAccentAlt, 0.8) }
                GradientStop { position: 1.0; color: Theme.withAlpha(segment.borderAccent, 0.65) }
            }
            PathRectangle { x: 0; y: 0; width: segment.width; height: segment.height; radius: segment.radius }
            PathRectangle { x: 1.5; y: 1.5; width: Math.max(0, segment.width - 3); height: Math.max(0, segment.height - 3); radius: Math.max(0, segment.radius - 1.5) }
        }
    }
}
