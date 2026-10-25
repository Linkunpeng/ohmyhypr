import QtQuick
import Quickshell
import "../services"

Text {
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    text: Qt.formatDateTime(clock.date, "ddd MM-dd  HH:mm")
    color: Theme.fg
    font.family: Theme.font
    font.pixelSize: Theme.fontSize
}
