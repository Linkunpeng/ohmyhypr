pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    function schedule(): void {
        if (Quickshell.env("OHMYHYPR_NESTED") !== "1")
            delay.restart();
    }

    Timer {
        id: delay
        interval: 1500
        onTriggered: recover.running = true
    }
    Process {
        id: recover
        command: [Omh.omh, "tray"]
    }
}
