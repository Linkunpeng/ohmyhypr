import QtQuick
import "../services"

Row {
    id: root
    spacing: 14
    readonly property var stats: SystemStats.metrics
    function percentage(value): string { return value === null || value === undefined ? "—" : value + "%"; }
    Text {
        text: "CPU " + root.percentage(root.stats.cpu)
        color: Theme.fg
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
    }
    Text {
        text: "温度 " + (root.stats.temperature === null || root.stats.temperature === undefined ? "—" : root.stats.temperature + "°C")
        color: (root.stats.temperature ?? 0) >= 80 ? Theme.urgent : Theme.fg
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
    }
    Text {
        text: "内存 " + root.percentage(root.stats.memory)
        color: Theme.fg
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
    }
    Text {
        text: (root.stats.muted ? "静音 " : "音量 ") + root.percentage(root.stats.volume)
        color: root.stats.muted ? Theme.muted : Theme.fg
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
    }
}
