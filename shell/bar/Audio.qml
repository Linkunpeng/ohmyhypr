import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../services"

// waybar group/audio: output volume; hover reveals the microphone. Click mutes,
// scroll changes volume, right click opens pavucontrol.
Drawer {
    id: root
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    function percent(node: PwNode): int {
        return Math.round((node?.audio?.volume ?? 0) * 100);
    }
    function wpctl(args: list<string>): void {
        Quickshell.execDetached(["wpctl", ...args]);
    }

    PwObjectTracker { objects: [root.sink, root.source] }

    leader: Module {
        readonly property bool muted: root.sink?.audio?.muted ?? false
        readonly property string icon: ["\uf026", "\uf027", "\udb81\udd7e", "\uf028"][Math.min(3, Math.floor(root.percent(root.sink) / 25))]
        text: !root.sink?.audio ? "" : muted ? "\udb81\udd81" : `${icon} ${root.percent(root.sink)}%`
        color: muted ? BarStyle.red : BarStyle.volume
        tooltip: root.sink ? `${icon} ${root.sink.description} | ${root.percent(root.sink)}%` : ""
        onClicked: button => button === Qt.RightButton
            ? Quickshell.execDetached(["pavucontrol", "-t", "3"])
            : root.wpctl(["set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
        onScrolled: steps => root.wpctl(["set-volume", "-l", "1.5", "@DEFAULT_AUDIO_SINK@", steps > 0 ? "5%+" : "5%-"])
    }

    Module {
        readonly property bool muted: root.source?.audio?.muted ?? false
        text: !root.source?.audio ? "" : muted ? "\uf131" : `\uf130 ${root.percent(root.source)}%`
        color: muted ? BarStyle.red : BarStyle.volume
        tooltip: root.source ? `${root.source.description} | ${root.percent(root.source)}%` : ""
        onClicked: button => button === Qt.RightButton
            ? Quickshell.execDetached(["pavucontrol", "-t", "4"])
            : root.wpctl(["set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"])
        onScrolled: steps => root.wpctl(["set-volume", "@DEFAULT_AUDIO_SOURCE@", steps > 0 ? "5%+" : "5%-"])
    }
}
