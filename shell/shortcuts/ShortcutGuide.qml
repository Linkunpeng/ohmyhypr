import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "../services"

PanelWindow {
    id: root
    readonly property bool open: Omh.shortcutGuideOpen
    property var bindings: []
    property string selectedGroup: "桌面"
    readonly property var groups: {
        const found = [];
        for (const bind of bindings) {
            const group = groupFor(bind);
            if (!found.includes(group)) found.push(group);
        }
        const preferred = ["桌面", "窗口", "工作区", "媒体", "AI", "其他"];
        return preferred.filter(group => found.includes(group)).concat(found.filter(group => !preferred.includes(group)).sort());
    }
    readonly property var visibleBindings: bindings.filter(bind => groupFor(bind) === selectedGroup)
    property string error: ""
    visible: open
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    color: Theme.withAlpha(Theme.bgSolid, 0.55)
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "omh-shortcuts"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    function groupFor(bind) {
        const match = (bind.description || "").match(/^\[group:([^\]]+)\]/);
        return match ? match[1] : "其他";
    }

    function formatKey(bind) {
        const mods = [];
        if (bind.modmask & 4) mods.push("Ctrl");
        if (bind.modmask & 8) mods.push("Alt");
        if (bind.modmask & 64) mods.push("Super");
        if (bind.modmask & 1) mods.push("Shift");
        if (bind.modmask & 2) mods.push("Caps Lock");
        if (bind.modmask & 16) mods.push("Mod2");
        if (bind.modmask & 32) mods.push("Mod3");
        if (bind.modmask & 128) mods.push("Mod5");
        const match = (bind.description || "").match(/\[key:([^\]]+)\]/);
        const names = { "mouse:272": "鼠标左键", "mouse:273": "鼠标右键", mouse_up: "滚轮向上", mouse_down: "滚轮向下", period: ".", minus: "-", equal: "=", SPACE: "Space", Return: "Enter" };
        const key = bind.key || (match ? match[1] : (bind.keycode ? "code:" + bind.keycode : "未知按键"));
        mods.push(names[key] || key);
        return mods.join(" + ") + (bind.release ? "（松开）" : "");
    }

    onVisibleChanged: {
        if (visible) {
            keys.forceActiveFocus();
            error = "";
            bindings = [];
            query.running = true;
        }
    }

    Process {
        id: query
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const result = JSON.parse(text);
                    if (!Array.isArray(result)) throw new Error("expected an array");
                    root.bindings = result;
                    if (!root.groups.includes(root.selectedGroup) && root.groups.length)
                        root.selectedGroup = root.groups[0];
                } catch (e) {
                    root.error = "无法解析快捷键列表";
                }
            }
        }
        onExited: (code, status) => {
            if (code !== 0) root.error = "无法读取快捷键列表";
        }
    }

    MouseArea { anchors.fill: parent; onClicked: Omh.shortcutGuideOpen = false }

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(620, root.width - 48)
        height: Math.min(660, root.height - 48)
        radius: Math.max(12, Theme.radius)
        color: Theme.bgSolid
        border.color: Theme.accent
        border.width: 1
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 14
            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "快捷键速查"
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: 22
                    font.bold: true
                }
                Text {
                    text: "Esc 关闭"
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 13
                }
            }
            Flow {
                Layout.fillWidth: true
                spacing: 8
                Repeater {
                    model: root.groups
                    delegate: Rectangle {
                        id: tab
                        required property string modelData
                        readonly property bool selected: modelData === root.selectedGroup
                        width: tabLabel.implicitWidth + 24
                        height: 32
                        radius: 8
                        color: selected ? Theme.accent : Theme.surface
                        Text {
                            id: tabLabel
                            anchors.centerIn: parent
                            text: tab.modelData
                            color: tab.selected ? Theme.bgSolid : Theme.fg
                            font.family: Theme.font
                            font.pixelSize: 13
                            font.bold: tab.selected
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedGroup = tab.modelData;
                                keys.contentY = 0;
                                keys.forceActiveFocus();
                            }
                        }
                    }
                }
            }
            Flickable {
                id: keys
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: entries.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                focus: true
                Keys.onEscapePressed: Omh.shortcutGuideOpen = false
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                Column {
                    id: entries
                    width: keys.width
                    spacing: 4
                    Repeater {
                        model: root.visibleBindings
                        delegate: Item {
                            id: entry
                            required property var modelData
                            width: entries.width
                            height: 36
                            RowLayout {
                                anchors.fill: parent
                                Text {
                                    Layout.fillWidth: true
                                    text: (entry.modelData.description || "未填写说明").replace(/^\[group:[^\]]+\]\s*/, "").replace(/\s*\[key:[^\]]+\]/, "") + (entry.modelData.submap ? " · " + entry.modelData.submap : "")
                                    color: Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: 14
                                    elide: Text.ElideRight
                                }
                                Rectangle {
                                    implicitWidth: keyText.implicitWidth + 18
                                    implicitHeight: 27
                                    radius: 6
                                    color: Theme.surface
                                    Text {
                                        id: keyText
                                        anchors.centerIn: parent
                                        text: root.formatKey(entry.modelData)
                                        color: Theme.fg
                                        font.family: Theme.font
                                        font.pixelSize: 12
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Text {
                Layout.fillWidth: true
                text: root.error || (query.running ? "正在读取快捷键…" : "选择分类 · 滚动查看 · Esc 或点击空白处关闭")
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 12
            }
        }
    }
}
