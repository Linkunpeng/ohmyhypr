import QtQuick
import "../services"

// waybar network#speed: link glyph and upload / download rate in a fixed
// 24-character field. Left click opens Wi-Fi, right click Bluetooth.
Module {
    id: root
    required property string screenName
    readonly property var net: SystemStats.metrics.net
    readonly property var wifi: (Connectivity.wifi.networks || []).find(n => n.connected) ?? null
    // dBm to waybar's signalStrength percentage.
    readonly property int strength: Math.max(0, Math.min(100, 2 * ((wifi?.signal ?? -60) + 100)))
    readonly property string glyph: !net ? "\udb80\udf19"
        : net.wireless ? ["\udb82\udd2f", "\udb82\udd1f", "\udb82\udd22", "\udb82\udd25", "\udb82\udd28"][Math.min(4, Math.floor(strength / 20))]
        : "\udb80\udf18"

    function rate(bytes: real): string {
        const units = ["", "k", "M", "G", "T"];
        let unit = 0;
        while (bytes >= 1000 && unit < units.length - 1) {
            bytes /= 1000;
            unit++;
        }
        return bytes.toFixed(1) + units[unit] + "B/s";
    }

    chars: 24
    text: net === undefined ? "" : net === null ? glyph
        : `${glyph} \uf139 ${rate(net.up)} \uf13a ${rate(net.down)}`
    tooltip: (!net ? "\udb80\udf19 Disconnected"
        : net.wireless ? `${Connectivity.wifi.connected || net.iface} ${glyph} ${strength}%`
        : `${net.iface} \udb80\udf18`) + "\nLeft Click: Wi-Fi\nRight Click: Bluetooth"
    onClicked: button => Connectivity.toggleMenu(button === Qt.RightButton ? "bluetooth" : "wifi", screenName)
}
