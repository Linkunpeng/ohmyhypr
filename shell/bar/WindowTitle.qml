import QtQuick
import Quickshell.Hyprland
import "../services"

// waybar hyprland/window with separate-outputs: last focused window on this monitor.
Module {
    id: root
    property HyprlandMonitor monitor
    property HyprlandToplevel window: null

    function track(): void {
        const active = Hyprland.activeToplevel;
        if (active && active.monitor === monitor)
            window = active;
    }

    function rewrite(title: string): string {
        let match = title.match(/^(.*) — Mozilla Firefox$/);
        if (match)
            return "\uf269 " + match[1];
        match = title.match(/^(.*) - (?:fish|zsh)$/);
        return match ? "> [" + match[1] + "]" : title;
    }

    Component.onCompleted: track()
    Connections {
        target: Hyprland
        function onActiveToplevelChanged() { root.track(); }
    }

    // Until this monitor gets focus, fall back to its workspace's last window.
    readonly property HyprlandWorkspace workspace: monitor?.activeWorkspace ?? null
    readonly property HyprlandToplevel shown: {
        if (window && window.workspace === workspace)
            return window;
        const last = String(workspace?.lastIpcObject?.lastwindow ?? "").replace(/^0x/, "");
        return last ? (workspace.toplevels.values.find(t => t.address === last) ?? null) : null;
    }

    text: shown ? BarStyle.elide(rewrite(shown.title), 25) : ""
}
