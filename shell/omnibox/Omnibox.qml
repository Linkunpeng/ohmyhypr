import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../services"

// M0 omnibox: free text goes to `omh ask`, streamed back line by line.
// M2 adds app/window/file results and intent → action execution.
PanelWindow {
    id: root

    visible: Omh.omniboxOpen
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "omh-omnibox"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    property string answer: ""

    onVisibleChanged: {
        if (visible) {
            input.text = "";
            answer = "";
            input.forceActiveFocus();
        } else {
            ask.running = false;
        }
    }

    Process {
        id: ask
        stdout: SplitParser {
            onRead: line => root.answer += (root.answer ? "\n" : "") + line
        }
        stderr: SplitParser {
            onRead: line => root.answer += "\n⚠ " + line
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Omh.omniboxOpen = false
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.22
        width: Math.min(720, parent.width * 0.6)
        height: column.implicitHeight + 24
        radius: Theme.radius
        color: Theme.bg
        border.color: Qt.rgba(1, 1, 1, 0.08)

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: column
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            TextField {
                id: input
                Layout.fillWidth: true
                placeholderText: "Ask anything, or describe what you want the desktop to do…"
                color: Theme.fg
                placeholderTextColor: Theme.muted
                font.family: Theme.font
                font.pixelSize: 18
                background: Item {}

                Keys.onEscapePressed: Omh.omniboxOpen = false
                onAccepted: {
                    if (text.trim() === "")
                        return;
                    root.answer = "";
                    ask.running = false;
                    ask.command = [Omh.omh, "ask", text];
                    ask.running = true;
                }
            }

            Text {
                Layout.fillWidth: true
                visible: root.answer !== "" || ask.running
                text: root.answer !== "" ? root.answer : "…"
                wrapMode: Text.Wrap
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                textFormat: Text.MarkdownText
            }
        }
    }
}
