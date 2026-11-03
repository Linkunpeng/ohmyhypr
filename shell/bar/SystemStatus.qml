import QtQuick
import "../services"

Row {
    id: root
    spacing: 14
    readonly property var stats: SystemStats.metrics
    function percentage(value): string { return value === null || value === undefined ? "—" : value + "%"; }

    StatusItem { glyph: "\uf4bc"; value: root.percentage(root.stats.cpu) }
    StatusItem {
        readonly property bool hot: (root.stats.temperature ?? 0) >= 80
        glyph: "\uf2c9"
        value: root.stats.temperature === null || root.stats.temperature === undefined ? "—" : root.stats.temperature + "°C"
        tint: hot ? Theme.urgent : Theme.accent
        textColor: hot ? Theme.urgent : Theme.fg
    }
    StatusItem { glyph: "\udb80\udf5b"; value: root.percentage(root.stats.memory) }
    StatusItem {
        glyph: root.stats.muted ? "\uf026" : "\uf028"
        value: root.percentage(root.stats.volume)
        tint: root.stats.muted ? Theme.muted : Theme.accent
        textColor: root.stats.muted ? Theme.muted : Theme.fg
    }
}
