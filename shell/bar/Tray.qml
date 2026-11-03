import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.DBusMenu
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../services"

// waybar tray: 20px icons, 4px apart, module padding on both sides.
Item {
    id: root
    readonly property int itemCount: icons.count
    visible: itemCount > 0
    implicitWidth: row.implicitWidth + BarStyle.padding * 2
    implicitHeight: BarStyle.moduleHeight
    Component.onCompleted: TrayRecovery.schedule()

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4
        Repeater {
            id: icons
            model: SystemTray.items
            delegate: Item {
                id: entry
                required property var modelData
                width: 20
                height: 20
                ToolTip.visible: mouse.containsMouse && !menu.visible
                ToolTip.delay: 600
                ToolTip.text: modelData.tooltipTitle || modelData.title || modelData.id
                IconImage {
                    id: icon
                    anchors.centerIn: parent
                    implicitSize: 20
                    source: entry.modelData.icon
                    opacity: entry.modelData.status === Status.Passive ? 0.6 : 1
                }
                Text {
                    anchors.centerIn: parent
                    visible: icon.status === Image.Error || icon.status === Image.Null
                    text: (entry.modelData.title || entry.modelData.id || "?").slice(0, 1).toUpperCase()
                    color: BarStyle.text
                    font.family: BarStyle.font
                    font.pixelSize: BarStyle.fontSize
                    font.bold: true
                }
                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: event => {
                        if (event.button === Qt.MiddleButton)
                            entry.modelData.secondaryActivate();
                        else if (event.button === Qt.LeftButton && !entry.modelData.onlyMenu)
                            entry.modelData.activate();
                        else if (entry.modelData.hasMenu)
                            menu.open();
                    }
                    onWheel: event => {
                        const horizontal = event.angleDelta.y === 0;
                        entry.modelData.scroll(horizontal ? event.angleDelta.x : event.angleDelta.y, horizontal);
                        event.accepted = true;
                    }
                }
                QsMenuAnchor {
                    id: menu
                    menu: entry.modelData.menu
                    anchor.item: entry
                    anchor.edges: Theme.barBottom ? Edges.Top : Edges.Bottom
                }
            }
        }
    }
}
