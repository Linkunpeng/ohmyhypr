import QtQuick
import Quickshell
import "../services"

Row {
    spacing: 8

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: clock.date.toLocaleString(Qt.locale("en_US"), "ddd MM-dd")
        color: Theme.muted
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 1
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: clock.date.toLocaleString(Qt.locale("en_US"), "HH:mm")
        color: Theme.fg
        font.family: Theme.font
        font.pixelSize: Theme.fontSize + 1
        font.bold: true
        font.features: { "tnum": 1 }
    }
}
