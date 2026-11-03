import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "../services"

// waybar custom/playerctl: "artist  title" of the playing (or first) MPRIS player.
Module {
    id: root
    readonly property MprisPlayer player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    readonly property string track: player && (player.trackArtist || player.trackTitle) ? `${player.trackArtist}  ${player.trackTitle}` : ""

    text: BarStyle.elide(track, 25)
    tooltip: player ? `${player.identity} : ${player.trackTitle}` : ""
    onClicked: button => {
        if (button === Qt.LeftButton && player.canGoPrevious)
            player.previous();
        else if (button === Qt.MiddleButton && player.canTogglePlaying)
            player.togglePlaying();
        else if (button === Qt.RightButton && player.canGoNext)
            player.next();
    }
    onScrolled: steps => Quickshell.execDetached(["wpctl", "set-volume", "-l", "1.5", "@DEFAULT_AUDIO_SINK@", steps > 0 ? "5%+" : "5%-"])
}
