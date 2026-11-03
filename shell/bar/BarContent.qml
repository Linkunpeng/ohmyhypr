import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../services"

// Port of JaKooLit's waybar "[TOP] Default" layout: left, center and right boxes.
Item {
    id: root
    required property ShellScreen screen
    property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property int boxY: Theme.barBottom ? 0 : BarStyle.marginTop
    readonly property alias leftBox: leftBox
    readonly property alias centerBox: centerBox
    readonly property alias rightBox: rightBox

    BarSegment {
        id: leftBox
        x: BarStyle.marginSide
        y: root.boxY
        Module { text: Cava.bars }
        Media {}
        Separator { text: "  " }
        WindowTitle { monitor: root.monitor }
    }

    BarSegment {
        id: centerBox
        // Centered like waybar's fixed-center, but pushed aside instead of overlapping.
        x: Math.max(leftBox.x + leftBox.width, Math.min(Math.round((root.width - width) / 2), rightBox.x - width))
        y: root.boxY
        AppDrawer {}
        Notifications { screenName: root.screen.name }
        Separator {}
        Workspaces { monitor: root.monitor }
        Clock {}
        Separator {}
        Module {
            text: Omh.idleInhibited ? " " : " "
            color: Omh.idleInhibited ? BarStyle.neon : BarStyle.teal
            tooltip: Omh.idleInhibited ? "Idle_inhibitor active" : "Idle_inhibitor not active"
            onClicked: Omh.idleInhibited = !Omh.idleInhibited
        }
        Module {
            text: "󰺁 HINT!"
            tooltip: "Left Click: Keybinds"
            onClicked: Omh.shortcutGuideOpen = !Omh.shortcutGuideOpen
        }
    }

    BarSegment {
        id: rightBox
        anchors.right: parent.right
        anchors.rightMargin: BarStyle.marginSide
        y: root.boxY
        Tray {}
        NetSpeed { screenName: root.screen.name }
        Separator {}
        Hardware {}
        Separator { text: "|" }
        Audio {}
        Separator {}
        Power {}
    }
}
