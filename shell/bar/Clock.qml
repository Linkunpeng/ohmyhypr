import QtQuick
import Quickshell
import "../services"

Text {
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    text: clock.date.toLocaleString(Qt.locale("en_US"), "ddd MM-dd  HH:mm")
    color: Theme.fg
    font.family: Theme.font
    font.pixelSize: Theme.fontSize
}
