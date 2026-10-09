import QtQuick
import Quickshell
import Quickshell.Io

// Painel da tela (clique no ícone de monitor da waybar), no molde do omarchy.monitor.
// Sem controle de brilho: o monitor é uma TV por HDMI, sem DDC/CI configurado.
Column {
    id: root

    property string align: "right"
    signal closeRequested()

    width: 380
    spacing: 10

    property var monitors: []
    readonly property var primary: monitors.length > 0 ? monitors[0] : null
    readonly property bool hdr: primary !== null && primary.colorManagementPreset === "hdr"
    property bool switching: false

    function bitDepth(format) {
        return /2101010/.test(String(format)) ? "10 bits" : "8 bits";
    }

    function describe(m) {
        return m.width + "×" + m.height + " · " + Math.round(m.refreshRate) + " Hz";
    }

    Process {
        id: monitorsProcess
        command: ["hyprctl", "-j", "monitors"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.monitors = JSON.parse(text);
                } catch (e) {
                    root.monitors = [];
                }
                root.switching = false;
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 700
        onTriggered: monitorsProcess.running = true
    }

    Component.onCompleted: monitorsProcess.running = true

    PanelHero {
        width: parent.width
        icon: root.monitors.length > 1 ? Theme.glyph(0xF037A) : Theme.glyph(0xF0379)
        title: "Tela"
        meta: root.primary ? root.primary.name + " · " + root.describe(root.primary) : ""
    }

    SectionHeader {
        text: "Cor"
        visible: root.primary !== null
    }

    Item {
        width: parent.width
        height: 34
        visible: root.primary !== null

        Column {
            anchors.left: parent.left
            anchors.right: hdrSwitch.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                text: "HDR"
                color: Theme.foreground
                font.family: Theme.font
                font.pixelSize: Theme.body
                font.bold: true
            }

            Text {
                width: parent.width
                text: root.hdr ? "Ligado: para filmes e jogos em HDR" : "Desligado: desktop em 10 bits"
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: Theme.bodySmall
                elide: Text.ElideRight
            }
        }

        ToggleSwitch {
            id: hdrSwitch
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            checked: root.hdr
            busy: root.switching
            onToggled: {
                root.switching = true;
                Quickshell.execDetached(["/home/palamar/.local/bin/hypr-hdr-toggle"]);
                refreshTimer.restart();
            }
        }
    }

    SectionHeader {
        text: "Telas"
        visible: root.monitors.length > 0
    }

    Column {
        width: parent.width
        spacing: 2

        Repeater {
            model: root.monitors

            PanelRow {
                required property var modelData

                width: parent.width
                icon: Theme.glyph(0xF0379)
                label: modelData.name
                detail: root.bitDepth(modelData.currentFormat) + " · escala " + modelData.scale
                clickable: false
                selected: modelData.focused
            }
        }
    }
}
