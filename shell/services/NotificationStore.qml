pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root
    property var items: []
    property bool centerOpen: false
    property string targetScreen: ""
    property bool recent: false
    property string preview: ""
    property int serial: 0
    property var server: null

    Component.onCompleted: {
        if (Quickshell.env("OHMYHYPR_NESTED") !== "1")
            server = serverComponent.createObject(root);
    }

    function dismissHint(): void {
        recent = false;
        hideHint.stop();
    }
    function toggle(screenName: string): void {
        if (centerOpen && targetScreen === screenName) {
            centerOpen = false;
        } else {
            Connectivity.openMenu = "";
            targetScreen = screenName;
            centerOpen = true;
            dismissHint();
        }
    }
    function remove(id: int): void {
        const item = items.find(n => n.id === id);
        items = items.filter(n => n.id !== id);
        if (item && item.live) item.live.dismiss();
    }
    function clear(): void {
        const previous = items;
        items = [];
        for (const item of previous) if (item.live) item.live.dismiss();
    }
    function invoke(id: int, index: int): void {
        const item = items.find(n => n.id === id);
        if (item && item.live && item.live.actions[index]) {
            item.live.actions[index].invoke();
            if (!item.live.resident) item.live.dismiss();
        }
    }
    function closed(id: int): void {
        items = items.map(n => n.id === id ? Object.assign({}, n, {live: null}) : n);
    }

    Component {
        id: serverComponent
        NotificationServer {
            keepOnReload: true
            bodySupported: true
            actionsSupported: true
            onNotification: n => {
                n.tracked = true;
                const id = n.id;
                n.closed.connect(() => root.closed(id));
                const now = Date.now() / 1000;
                const entry = {
                    id: id, title: n.summary, body: n.body, app: n.appName, live: n,
                    time: now, deadline: n.expireTimeout === 0 ? 0 : now + (n.expireTimeout > 0 ? n.expireTimeout / 1000 : 8),
                    actions: n.actions.map(a => a.text)
                };
                const old = root.items.filter(x => x.id !== id);
                if (old.length >= 50 && old[old.length - 1].live) old[old.length - 1].live.dismiss();
                root.items = [entry].concat(old).slice(0, 50);
                if (!n.lastGeneration) {
                    const message = String(n.summary || n.body || n.appName || "New notification")
                        .replace(/<[^>]*>/g, " ").replace(/[\s\x00-\x1f]+/g, " ").trim();
                    const chars = Array.from(message);
                    root.preview = chars.slice(0, 28).join("") + (chars.length > 28 ? "…" : "");
                    root.serial++;
                    root.recent = true;
                    hideHint.restart();
                }
            }
        }
    }
    Timer {
        id: hideHint
        interval: 10000
        onTriggered: root.recent = false
    }
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            const now = Date.now() / 1000;
            for (const item of root.items)
                if (item.live && item.deadline && now >= item.deadline) item.live.expire();
        }
    }
    IpcHandler {
        target: "notifications"
        function toggleNotifications(screenName: string): void { root.toggle(screenName); }
        function closeCenter(): void { root.centerOpen = false; }
        function removeNotification(id: int): void { root.remove(id); }
        function clearNotifications(): void { root.clear(); }
        function status(): string {
            return JSON.stringify({notifications: root.items.length, notificationSerial: root.serial,
                notificationPreview: root.preview, centerOpen: root.centerOpen});
        }
    }
}
