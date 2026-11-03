import QtQuick
import "../services"

// waybar custom/swaync: count and bell with a red dot while notifications are
// waiting; a new one shows its preview beside the bell for a few seconds.
Row {
    id: root
    required property string screenName
    readonly property int count: NotificationStore.items.length
    spacing: BarStyle.spacing

    function toggle(): void {
        NotificationStore.dismissHint();
        NotificationStore.toggle(screenName);
    }

    Module {
        // Rich text collapses spaces, hence &nbsp;.
        text: (root.count > 0 ? root.count + "&nbsp;" : "") + "\uf0a2"
            + (root.count > 0 ? "<sup><span style=\"color:red\">\uf444</span></sup>" : "") + "&nbsp;"
        textFormat: Text.RichText
        tooltip: "Left Click: Notification Center\nRight Click: Clear All"
        onClicked: button => {
            if (button === Qt.RightButton)
                NotificationStore.clear();
            else
                root.toggle();
        }
    }

    Module {
        text: NotificationStore.recent ? NotificationStore.preview : ""
        color: BarStyle.gold
        onClicked: root.toggle()
    }
}
