import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../services"

PanelWindow {
    id: root
    visible: Omh.wallpaperPickerOpen
    screen: Quickshell.screens.find(s => s.name === root.targetScreen) ?? Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    color: Theme.withAlpha(Theme.bgSolid, 0.55)
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "omh-wallpapers"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    property var images: []
    property string directory: ""
    readonly property string targetScreen: Omh.wallpaperTargetScreen
    property string error: ""

    function refresh(): void {
        error = "";
        scan.command = [Omh.omh, "wallpaper", "list", "--screen", targetScreen];
        scan.running = true;
    }
    function apply(): void {
        const image = images[grid.currentIndex];
        if (!image || update.running || !targetScreen) return;
        error = "";
        update.command = [Omh.omh, "wallpaper", "set", image.path, "--screen", targetScreen];
        update.running = true;
    }
    onVisibleChanged: {
        if (visible) {
            refresh();
            grid.forceActiveFocus();
        }
    }

    Process {
        id: scan
        command: [Omh.omh, "wallpaper", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const result = JSON.parse(text);
                    root.directory = result.directory;
                    root.images = result.items;
                    root.error = result.error || "";
                    grid.currentIndex = Math.max(0, root.images.findIndex(i => i.current));
                } catch (e) {
                    root.error = "无法读取壁纸目录";
                }
            }
        }
        stderr: StdioCollector { id: scanError }
        onExited: (code, status) => {
            if (code !== 0) root.error = scanError.text || "无法读取壁纸目录";
        }
    }
    Process {
        id: update
        stderr: StdioCollector { id: updateError }
        onExited: (code, status) => {
            if (code === 0) Omh.wallpaperPickerOpen = false;
            else root.error = updateError.text || "壁纸应用失败";
        }
    }

    MouseArea { anchors.fill: parent; onClicked: if (!update.running) Omh.wallpaperPickerOpen = false }
    Rectangle {
        anchors.centerIn: parent
        width: Math.min(1040, root.width - 48)
        height: Math.min(720, root.height - 96)
        color: Theme.bgSolid
        radius: Math.max(12, Theme.radius)
        border.color: Theme.accent
        border.width: 1
        MouseArea { anchors.fill: parent }
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 14
            Text {
                text: "选择壁纸 · " + root.targetScreen
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: 22
            }
            Text {
                text: root.directory
                color: Theme.muted
                font.family: Theme.font
                Layout.fillWidth: true
                elide: Text.ElideMiddle
            }
            GridView {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: root.images
                cellWidth: width / Math.max(1, Math.floor(width / 220))
                cellHeight: 168
                keyNavigationEnabled: true
                focus: true
                ScrollBar.vertical: ScrollBar {}
                Keys.onEscapePressed: if (!update.running) Omh.wallpaperPickerOpen = false
                Keys.onReturnPressed: root.apply()
                Keys.onEnterPressed: root.apply()
                delegate: Item {
                    id: tile
                    required property var modelData
                    required property int index
                    width: grid.cellWidth
                    height: grid.cellHeight
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 5
                        radius: 8
                        color: Theme.surface
                        border.width: tile.index === grid.currentIndex ? 3 : 1
                        border.color: tile.index === grid.currentIndex ? Theme.accent : Theme.muted
                        Image {
                            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 5 }
                            height: 116
                            source: tile.modelData.url
                            sourceSize: Qt.size(400, 240)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                        Text {
                            anchors { bottom: parent.bottom; left: parent.left; right: parent.right; margins: 10 }
                            text: (tile.modelData.current ? "● " : "") + tile.modelData.name
                            color: Theme.fg
                            font.family: Theme.font
                            elide: Text.ElideMiddle
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: { grid.currentIndex = tile.index; grid.forceActiveFocus(); }
                            onDoubleClicked: { grid.currentIndex = tile.index; root.apply(); }
                        }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    visible: root.images.length === 0
                    text: scan.running ? "正在读取壁纸…" : "目录中暂无图片"
                    color: Theme.muted
                    font.family: Theme.font
                }
            }
            Text {
                Layout.fillWidth: true
                visible: root.error !== ""
                text: root.error
                color: Theme.urgent
                wrapMode: Text.Wrap
                font.family: Theme.font
            }
            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: update.running ? "正在取色并应用…" : "方向键选择 · Enter 应用 · Esc 关闭"
                    color: Theme.muted
                    font.family: Theme.font
                }
                Button { text: "刷新"; enabled: !scan.running && !update.running; onClicked: root.refresh() }
                Button { text: "应用到此屏幕"; enabled: root.images.length > 0 && !update.running; onClicked: root.apply() }
                Button { text: "关闭"; enabled: !update.running; onClicked: Omh.wallpaperPickerOpen = false }
            }
        }
    }
}
