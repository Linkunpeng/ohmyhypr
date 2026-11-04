import QtQuick
import "../services"

Module {
    readonly property var stats: SystemStats.metrics
    function percent(value): string { return value == null ? "—" : value + "%"; }

    text: "GPU " + percent(stats.gpu) + "  VRAM " + percent(stats.vram)
    tooltip: "GPU utilization and video memory usage"
}
