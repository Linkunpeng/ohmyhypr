pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var metrics: ({})
    Process {
        running: true
        command: [Omh.omh, "metrics", "--watch"]
        stdout: SplitParser {
            onRead: line => {
                try { root.metrics = JSON.parse(line); }
                catch (e) { console.warn("system metrics:", e); }
            }
        }
        onExited: root.metrics = ({})
    }
}
