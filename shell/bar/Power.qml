import QtQuick
import Quickshell
import "../services"

// waybar group/status: power button opening wlogout; hover reveals lock on its left.
Drawer {
    leftToRight: false

    leader: Module {
        text: " ⏻ "
        tooltip: "Left Click: Logout Menu"
        onClicked: Quickshell.execDetached(["wlogout"])
    }

    Module {
        text: "\udb80\udf3e"
        color: BarStyle.teal
        tooltip: "Screen Lock"
        onClicked: Omh.run(["lock"])
    }
}
