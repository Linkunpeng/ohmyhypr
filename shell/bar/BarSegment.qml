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
    color: Qt.rgba(Theme.bgSolid.r, Theme.bgSolid.g, Theme.bgSolid.b, Theme.palette.bar_opacity ?? 0.2)

    // Glass sheen: a faint highlight fading out over the top half.
    Rectangle {
        anchors.fill: parent
        radius: segment.radius
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, Theme.dark ? 0.07 : 0.18) }
            GradientStop { position: 0.55; color: Qt.rgba(1, 1, 1, 0) }
        }
    }

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
                GradientStop { position: 0.0; color: Theme.withAlpha(segment.borderAccent, 0.4) }
                GradientStop { position: 0.12; color: Theme.withAlpha(Qt.lighter(segment.borderAccent, 1.25), 0.85) }
                GradientStop { position: 0.26; color: Theme.withAlpha(segment.borderAccentAlt, 0.55) }
                GradientStop { position: 0.55; color: Theme.withAlpha(segment.borderAccent, 0.4) }
                GradientStop { position: 0.78; color: Theme.withAlpha(segment.borderAccentAlt, 0.55) }
                GradientStop { position: 1.0; color: Theme.withAlpha(segment.borderAccent, 0.4) }
            }
            PathRectangle { x: 0; y: 0; width: segment.width; height: segment.height; radius: segment.radius }
            PathRectangle { x: 1; y: 1; width: Math.max(0, segment.width - 2); height: Math.max(0, segment.height - 2); radius: Math.max(0, segment.radius - 1) }
        }
    }
}
