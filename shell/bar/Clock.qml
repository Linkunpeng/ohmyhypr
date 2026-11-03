import QtQuick
import Quickshell
import "../services"

// waybar clock: sapphire HH:mm:ss in a bordered pill; click for the long date,
// hover for the year calendar.
Rectangle {
    id: root
    property bool alt: false
    readonly property string today: Qt.formatDate(clock.date, "yyyy-MM-dd")

    implicitWidth: label.implicitWidth + 4
    implicitHeight: BarStyle.moduleHeight
    radius: BarStyle.radius
    color: "transparent"
    border.width: 2
    border.color: BarStyle.border

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Module {
        id: label
        anchors.centerIn: parent
        color: BarStyle.sapphire
        text: "\uf017 " + (root.alt
            ? Qt.formatDateTime(clock.date, "HH:mm") + "  \uf073 " + Qt.locale().toString(clock.date, "yyyy, dd MMMM, dddd")
            : Qt.formatDateTime(clock.date, "HH:mm:ss"))
        tooltip: root.calendar(Number(root.today.slice(0, 4)), root.today)
        tooltipFormat: Text.RichText
        onClicked: button => {
            if (button === Qt.LeftButton)
                root.alt = !root.alt;
        }
    }

    // Year view like waybar's calendar (3 months per row, ISO weeks on the right).
    function calendar(year: int, today: string): string {
        const locale = Qt.locale();
        const firstDay = locale.firstDayOfWeek % 7;
        const paint = (color, text) => `<span style="color:${color}">${text}</span>`;
        const pad = (text, width) => text + " ".repeat(Math.max(0, width - text.length));
        const isoWeek = date => {
            const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
            d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay() || 7));
            return Math.ceil(((d - Date.UTC(d.getUTCFullYear(), 0, 1)) / 86400000 + 1) / 7);
        };
        const weekdays = [0, 1, 2, 3, 4, 5, 6].map(i => locale.dayName((firstDay + i) % 7, Locale.ShortFormat).slice(0, 2)).join(" ");

        // Each month is 8 lines of 24 visible characters: 20 for days, 4 for the week.
        const month = m => {
            const name = locale.standaloneMonthName(m, Locale.LongFormat);
            const left = Math.floor((20 - name.length) / 2);
            const lines = [paint("#ffead3", " ".repeat(left) + name) + " ".repeat(24 - left - name.length),
                           paint("#ffcc66", weekdays) + "    "];
            const first = new Date(year, m, 1);
            const days = new Date(year, m + 1, 0).getDate();
            let cells = [];
            const offset = (first.getDay() - firstDay + 7) % 7;
            for (let i = 0; i < offset; i++) cells.push("  ");
            for (let day = 1; day <= days; day++) {
                const date = new Date(year, m, day);
                const text = String(day).padStart(2, " ");
                const iso = Qt.formatDate(date, "yyyy-MM-dd");
                cells.push(iso === today ? `<u>${paint("#ff6699", text)}</u>` : paint("#ecc6d9", text));
                if (cells.length === 7 || day === days) {
                    const filler = "   ".repeat(7 - cells.length);
                    // The row's last day shares its ISO week with the rest of a Sunday-first row.
                    lines.push(cells.join(" ") + filler + " " + paint("#99ffdd", "W" + String(isoWeek(date)).padStart(2, "0")));
                    cells = [];
                }
            }
            while (lines.length < 8) lines.push(" ".repeat(24));
            return lines;
        };

        const rows = [];
        for (let m = 0; m < 12; m += 3) {
            const blocks = [month(m), month(m + 1), month(m + 2)];
            for (let i = 0; i < 8; i++)
                rows.push(blocks.map(b => b[i]).join("    "));
        }
        return `<pre style="font-family:'${BarStyle.font}'; font-size:11px; font-weight:bold">${rows.join("\n")}</pre>`;
    }
}
