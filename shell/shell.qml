//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

// ohmyhypr shell — UI layer of the AI native desktop.
// Launched by hypr/lua/omh/autostart.lua as `qs -p <repo>/shell`.

import QtQuick
import Quickshell
import Quickshell.Hyprland
import "bar"
import "connectivity"
import "omnibox"
import "notifications"
import "services"
import "shortcuts"
import "themes"
import "wallpaper"

ShellRoot {
    // Initialize the notification server even before the first bar is visible.
    property var notificationService: NotificationStore
    Variants {
        model: Quickshell.screens
        delegate: Wallpaper {}
    }

    Variants {
        model: Quickshell.screens
        delegate: Bar {}
    }

    Variants {
        model: Quickshell.screens
        delegate: NotificationDismiss {}
    }

    Variants {
        model: Quickshell.screens
        delegate: NotificationCenter {}
    }

    Variants {
        model: Quickshell.screens
        delegate: ConnectivityDismiss {}
    }

    Variants {
        model: Quickshell.screens
        delegate: ConnectivityMenu {}
    }

    Omnibox {}

    ThemePicker {}

    WallpaperPicker {}

    ShortcutGuide {}

    GlobalShortcut {
        appid: "ohmyhypr"
        name: "toggle-bar"
        description: "Toggle status bar"
        onPressed: Omh.barHidden = !Omh.barHidden
    }

    GlobalShortcut {
        appid: "ohmyhypr"
        name: "shortcuts"
        description: "Shortcut guide"
        onPressed: Omh.shortcutGuideOpen = !Omh.shortcutGuideOpen
    }

    GlobalShortcut {
        appid: "ohmyhypr"
        name: "wallpaper"
        description: "Wallpaper picker"
        onPressed: Omh.toggleWallpaperPicker()
    }

    GlobalShortcut {
        appid: "ohmyhypr"
        name: "themes"
        description: "Theme picker"
        onPressed: Omh.themePickerOpen = !Omh.themePickerOpen
    }

    // Entry points bound in hypr/lua/omh/ai.lua as hl.dsp.global("ohmyhypr:<name>").
    GlobalShortcut {
        appid: "ohmyhypr"
        name: "omnibox"
        description: "Unified launcher and natural-language intent"
        onPressed: Omh.omniboxOpen = !Omh.omniboxOpen
    }

    // Not implemented yet: announce instead of failing silently.
    Repeater {
        model: ["selection", "sidebar", "voice-start"]
        delegate: Item {
            id: stub
            required property string modelData
            GlobalShortcut {
                appid: "ohmyhypr"
                name: stub.modelData
                onPressed: Omh.notify("ohmyhypr", stub.modelData + " is on the roadmap (docs/roadmap.md)")
            }
        }
    }
}
