import QtQuick
import "../services"

// waybar group drawer: the leader stays visible, the other modules slide out
// beside it while the pointer is over the group.
Item {
    id: root
    property bool leftToRight: true
    property alias leader: leaderSlot.data
    default property alias items: drawerRow.data
    property bool open: hover.hovered

    implicitWidth: row.implicitWidth
    implicitHeight: BarStyle.moduleHeight

    HoverHandler { id: hover }

    Row {
        id: row
        spacing: BarStyle.spacing
        layoutDirection: root.leftToRight ? Qt.LeftToRight : Qt.RightToLeft

        Row { id: leaderSlot }

        Item {
            id: reveal
            visible: width > 0
            width: root.open ? drawerRow.implicitWidth : 0
            height: BarStyle.moduleHeight
            clip: true
            Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
            Row {
                id: drawerRow
                x: root.leftToRight ? 0 : reveal.width - width
                spacing: BarStyle.spacing
            }
        }
    }
}
