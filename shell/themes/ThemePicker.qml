import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../services"

// One-click theme switching: cards with wallpaper, palette and avatar.
// ←/→ to choose, Enter to apply, Esc to close.
PanelWindow {
    id: root

    visible: Omh.themePickerOpen
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: Theme.withAlpha(Theme.bgSolid, 0.45)
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "omh-themes"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    property var themes: []
    property int selected: 0

    onVisibleChanged: {
        if (visible) {
            list.running = true;
            keys.forceActiveFocus();
        }
    }

    Process {
        id: list
        command: [Omh.omh, "theme", "list", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.themes = JSON.parse(text);
                    root.selected = Math.max(0, root.themes.findIndex(t => t.current));
                } catch (e) {
                    console.warn("theme list:", e);
                }
            }
        }
    }

    function apply(index: int): void {
        const t = themes[index];
        if (!t)
            return;
        Omh.run(["theme", "apply", t.id]);
        Omh.themePickerOpen = false;
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Omh.themePickerOpen = false
    }

    Item {
        id: keys
        focus: true
        Keys.onEscapePressed: Omh.themePickerOpen = false
        Keys.onLeftPressed: root.selected = (root.selected + root.themes.length - 1) % root.themes.length
        Keys.onRightPressed: root.selected = (root.selected + 1) % root.themes.length
        Keys.onReturnPressed: root.apply(root.selected)
        Keys.onEnterPressed: root.apply(root.selected)
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 18

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "选择主题"
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: 22
        }

        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 18

            Repeater {
                model: root.themes

                delegate: Rectangle {
                    id: card

                    required property var modelData
                    required property int index
                    readonly property var pal: modelData.palette ?? ({})
                    readonly property bool chosen: index === root.selected

                    width: 260
                    height: 230
                    radius: modelData.radius ?? 12
                    color: pal.bg ?? "#222"
                    border.width: chosen ? 3 : 1
                    border.color: chosen ? (pal.accent ?? "white") : Qt.rgba(1, 1, 1, 0.12)
                    scale: chosen ? 1.04 : 1
                    clip: true
                    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                    // preview: wallpaper or gradient
                    Rectangle {
                        id: preview
                        x: 0
                        y: 0
                        width: parent.width
                        height: 140
                        gradient: Gradient {
                            GradientStop { position: 0; color: card.pal.bg ?? "#222" }
                            GradientStop { position: 1; color: card.pal.accent_alt ?? "#555" }
                        }
                        Image {
                            anchors.fill: parent
                            visible: (card.modelData.wallpaper ?? "") !== ""
                            source: card.modelData.wallpaper ? "file://" + card.modelData.wallpaper : ""
                            fillMode: Image.PreserveAspectCrop
                            sourceSize: Qt.size(520, 280)
                            asynchronous: true
                        }
                        // mini bar
                        Rectangle {
                            x: 8
                            y: 8
                            width: parent.width - 16
                            height: 16
                            radius: Math.min(card.radius, 8)
                            color: Qt.rgba(Qt.color(card.pal.bg ?? "#222").r, Qt.color(card.pal.bg ?? "#222").g, Qt.color(card.pal.bg ?? "#222").b, 0.85)
                            Rectangle {
                                x: 6
                                anchors.verticalCenter: parent.verticalCenter
                                width: 22
                                height: 8
                                radius: Math.min(card.radius, 4)
                                color: card.pal.accent ?? "white"
                            }
                        }
                    }

                    Column {
                        x: 14
                        y: preview.height + 10
                        width: parent.width - 28
                        spacing: 6

                        Text {
                            text: (card.modelData.current ? "● " : "") + (card.modelData.name ?? card.modelData.id)
                            color: card.pal.fg ?? "white"
                            font.family: Theme.font
                            font.pixelSize: 15
                            font.bold: true
                            elide: Text.ElideRight
                            width: parent.width
                        }
                        Text {
                            text: card.modelData.avatar ? "形象 · " + card.modelData.avatar : "无形象"
                            color: Qt.rgba(Qt.color(card.pal.fg ?? "white").r, Qt.color(card.pal.fg ?? "white").g, Qt.color(card.pal.fg ?? "white").b, 0.6)
                            font.family: Theme.font
                            font.pixelSize: 12
                        }
                        Row {
                            spacing: 6
                            Repeater {
                                model: ["bg", "surface", "fg", "accent", "accent_alt"]
                                delegate: Rectangle {
                                    required property string modelData
                                    width: 18
                                    height: 18
                                    radius: Math.min(card.radius, 9)
                                    color: card.pal[modelData] ?? "transparent"
                                    border.color: Qt.rgba(1, 1, 1, 0.2)
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: root.selected = card.index
                        onClicked: root.apply(card.index)
                    }
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "← →  选择     Enter  应用     Esc  关闭"
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: 12
        }
    }
}
