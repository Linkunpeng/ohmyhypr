pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The notification service supplies a short preview alongside its event counter.
Singleton {
    id: root
    property bool recent: false
    property int lastSerial: -1
    property string preview: ""

    function dismissHint(): void {
        recent = false;
        hideHint.stop();
    }

    Timer {
        id: hideHint
        interval: 10000
        onTriggered: root.recent = false
    }
    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: if (!query.running) query.running = true
    }
    Process {
        id: query
        command: ["qs", "ipc", "-p", (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/quickshell", "call", "notifications", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    const serial = data.notificationSerial;
                    if (typeof serial !== "number") return;
                    if (root.lastSerial >= 0 && serial > root.lastSerial) {
                        root.preview = typeof data.notificationPreview === "string" ? data.notificationPreview : "";
                        root.recent = true;
                        hideHint.restart();
                    }
                    root.lastSerial = serial;
                } catch (e) {
                    // The legacy notification service may not be running.
                }
            }
        }
    }
}
