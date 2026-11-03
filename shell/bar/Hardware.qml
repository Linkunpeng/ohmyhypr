import QtQuick
import "../services"

// waybar group/mobo_drawer: temperature; hover reveals CPU, memory and disk.
Drawer {
    id: root
    readonly property var stats: SystemStats.metrics
    readonly property bool critical: (stats.temperature ?? 0) >= 82
    property bool memoryPercent: false

    leader: Module {
        text: root.stats.temperature == null ? "" : root.stats.temperature + "°C \udb80\ude38"
        Rectangle {
            z: -1
            anchors.fill: parent
            color: BarStyle.red
            visible: root.critical
        }
    }

    Module {
        text: root.stats.cpu == null ? "" : root.stats.cpu + "% \udb80\udf5b"
        color: BarStyle.mauve
    }
    Module {
        text: root.stats.memory == null ? ""
            : (root.memoryPercent ? root.stats.memory + "%" : root.stats.memory_gib.toFixed(1) + "G") + " \udb83\udf86"
        color: BarStyle.sapphire
        onClicked: root.memoryPercent = !root.memoryPercent
    }
    Module {
        text: root.stats.disk == null ? "" : root.stats.disk + "% \udb80\udeca"
        color: BarStyle.sky
        tooltip: root.stats.disk == null ? "" : `${root.stats.disk}% used on /`
    }
}
