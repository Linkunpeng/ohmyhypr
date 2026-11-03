pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var wifi: ({ available: false, enabled: false, connected: "", networks: [] })
    property var bluetooth: ({ available: false, enabled: false, devices: [] })
    property string openMenu: ""
    property string targetScreen: ""
    property string error: ""
    readonly property bool busy: action.running

    function toggleMenu(kind: string, screen: string): void {
        if (openMenu === kind && targetScreen === screen) openMenu = "";
        else { NotificationStore.centerOpen = false; targetScreen = screen; openMenu = kind; error = ""; refresh(); }
    }
    function refresh(): void { if (!query.running) query.running = true; }
    function run(kind: string, operation: string, target: string): void {
        if (action.running) return;
        error = "";
        action.command = [Omh.omh, "connectivity", "action", kind, operation, target];
        action.running = true;
    }
    function openTerminal(args: list<string>): void {
        // Passwords and pairing confirmations stay in the terminal, never in arguments.
        Quickshell.execDetached([Quickshell.env("OHMYHYPR_TERMINAL") || "kitty", "-e", ...args]);
        openMenu = "";
    }

    Timer { interval: 5000; repeat: true; running: true; triggeredOnStart: true; onTriggered: root.refresh() }
    Timer { id: refreshAfterScan; interval: 1400; onTriggered: root.refresh() }
    Process {
        id: query
        command: [Omh.omh, "connectivity", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    root.wifi = data.wifi;
                    root.bluetooth = data.bluetooth;
                } catch (e) { console.warn("connectivity status: invalid response"); }
            }
        }
    }
    Process {
        id: action
        stderr: StdioCollector { id: actionError }
        onExited: (code, status) => {
            if (code !== 0) root.error = actionError.text.trim() || "Action failed";
            root.refresh();
            refreshAfterScan.restart();
        }
    }
    IpcHandler {
        target: "connectivity"
        function toggle(kind: string, screen: string): void {
            if (kind === "wifi" || kind === "bluetooth") root.toggleMenu(kind, screen);
        }
        function close(): void { root.openMenu = ""; }
    }
}
