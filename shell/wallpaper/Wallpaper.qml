import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"

// Theme wallpaper with crossfade; palette gradient when the theme has none.
PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: Theme.bgSolid
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "omh-wallpaper"

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.bgSolid }
            GradientStop { position: 0.65; color: Qt.darker(Theme.surface, 1.1) }
            GradientStop { position: 1.0; color: Theme.withAlpha(Theme.accentAlt, 0.35) }
        }
    }

    readonly property var wallpaperSpec: Theme.data.wallpapers?.[screen.name] ?? Theme.data.wallpaper ?? ({})
    readonly property string imagePath: wallpaperSpec.path ?? ""
    readonly property string imageFit: wallpaperSpec.fit ?? "cover"
    property bool showA: true

    Image {
        id: a
        anchors.fill: parent
        fillMode: root.imageFit === "contain" ? Image.PreserveAspectFit : root.imageFit === "center" ? Image.Pad : Image.PreserveAspectCrop
        asynchronous: true
        sourceSize: Qt.size(root.width, root.height)
        opacity: root.showA ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 700; easing.type: Easing.InOutQuad } }
    }

    Image {
        id: b
        anchors.fill: parent
        fillMode: a.fillMode
        asynchronous: true
        sourceSize: Qt.size(root.width, root.height)
        opacity: root.showA ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 700; easing.type: Easing.InOutQuad } }
    }

    function show(path: string): void {
        const src = path ? "file://" + path.split("/").map(encodeURIComponent).join("/") : "";
        const next = showA ? b : a;
        next.source = src;
        showA = !showA;
    }

    onImagePathChanged: root.show(imagePath)
    Component.onCompleted: show(imagePath)
}
