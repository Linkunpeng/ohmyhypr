//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

// ohmyhypr shell — UI layer of the AI native desktop.
// Launched by hypr/lua/omh/autostart.lua as `qs -p <repo>/shell`.

import QtQuick
import Quickshell
import Quickshell.Hyprland
import "bar"
import "omnibox"
import "services"

ShellRoot {
    Variants {
        model: Quickshell.screens
        delegate: Bar {}
    }

    Omnibox {}

    // Entry points bound in hypr/lua/omh/ai.lua as hl.dsp.global("ohmyhypr:<name>").
    GlobalShortcut {
        appid: "ohmyhypr"
        name: "omnibox"
        description: "Unified launcher and natural-language intent"
        onPressed: Omh.omniboxOpen = !Omh.omniboxOpen
    }

    // Not implemented yet: announce instead of failing silently.
    Repeater {
        model: ["screen-ask", "selection", "sidebar", "voice-start"]
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
