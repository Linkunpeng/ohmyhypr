import QtQuick
import "../services"

// waybar group/app_drawer: launcher button; hover reveals theme, files, terminal,
// browser and wallpaper shortcuts.
Drawer {
    leader: Module {
        text: " \uf359 "
        tooltip: "Left Click: Launcher\nMiddle Click: Wallpaper Menu\nRight Click: Theme Menu"
        onClicked: button => {
            if (button === Qt.LeftButton)
                Omh.omniboxOpen = !Omh.omniboxOpen;
            else if (button === Qt.MiddleButton)
                Omh.toggleWallpaperPicker();
            else
                Omh.themePickerOpen = !Omh.themePickerOpen;
        }
    }

    Module {
        text: "\udb81\udd0e "
        tooltip: "Left Click: Theme Menu\nMiddle Click: Wallpaper Menu"
        onClicked: button => {
            if (button === Qt.MiddleButton)
                Omh.toggleWallpaperPicker();
            else
                Omh.themePickerOpen = !Omh.themePickerOpen;
        }
    }
    Module {
        text: "\uf0c5 "
        tooltip: "File Manager"
        onClicked: Omh.launch("files")
    }
    Module {
        text: "\uf120 "
        tooltip: "Launch Terminal"
        onClicked: Omh.launch("terminal")
    }
    Module {
        text: "\ue658 "
        tooltip: "Launch Browser"
        onClicked: Omh.launch("browser")
    }
    Module {
        text: "\ueb51 "
        tooltip: "Wallpaper Menu"
        onClicked: Omh.toggleWallpaperPicker()
    }
}
