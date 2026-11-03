pragma Singleton

// Ten-bar audio spectrum from cava's raw ASCII output (custom/cava_mviz in waybar).

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property string levels: "▁▂▃▄▅▆▇█"
    property string bars: ""

    Process {
        running: true
        command: ["cava", "-p", Quickshell.shellDir + "/bar/cava.conf"]
        stdout: SplitParser {
            onRead: line => root.bars = line.split(";").filter(v => v !== "").map(v => root.levels[Math.min(7, Number(v))] ?? "").join("")
        }
        onExited: root.bars = ""
    }
}
