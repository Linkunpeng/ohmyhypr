import QtQuick
import "../services"

// Hairline divider that fades out at both ends.
Rectangle {
    implicitWidth: 1
    implicitHeight: 18
    gradient: Gradient {
        GradientStop { position: 0.0; color: Theme.withAlpha(Theme.accent, 0) }
        GradientStop { position: 0.5; color: Theme.withAlpha(Theme.accent, 0.55) }
        GradientStop { position: 1.0; color: Theme.withAlpha(Theme.accent, 0) }
    }
}
