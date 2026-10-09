import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Painel de som (clique no ícone de volume da waybar), no molde do omarchy.audio:
// volume e escolha da saída, microfone e volume de cada aplicativo.
Column {
    id: root

    property string align: "right"
    signal closeRequested()

    width: 380
    spacing: 10

    readonly property var nodes: Pipewire.nodes ? Pipewire.nodes.values : []
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    // As listas guardam só id + nome: segurar o PwNode num modelo derruba o
    // shell quando o PipeWire apaga o nó (lição do Model.js do Omarchy).
    function rows(accept) {
        const out = [];
        for (const n of root.nodes) {
            if (n && accept(n))
                out.push({ id: n.id, name: String(n.name || "") });
        }
        return out;
    }

    function resolve(row) {
        for (const n of root.nodes) {
            if (n && n.id === row.id && String(n.name || "") === row.name)
                return n;
        }
        return null;
    }

    function isPlaybackStream(n) {
        if (!n.isStream)
            return false;
        if (n.isSink)
            return true;
        return String(n.type || "").indexOf("Output") !== -1;
    }

    readonly property var sinkRows: rows(n => n.audio && n.isSink && !n.isStream)
    readonly property var sourceRows: rows(n => n.audio && !n.isSink && !n.isStream)
    readonly property var streamRows: rows(n => n.audio && isPlaybackStream(n))

    PwObjectTracker {
        objects: {
            const list = [root.sink, root.source];
            for (const row of root.sinkRows.concat(root.sourceRows, root.streamRows))
                list.push(root.resolve(row));
            return list.filter(n => n !== null);
        }
    }

    readonly property bool hasOutput: sink !== null && sink.audio !== null
    readonly property real outputVolume: hasOutput ? sink.audio.volume : 0
    readonly property bool outputMuted: hasOutput && sink.audio.muted

    function nodeLabel(n) {
        if (!n)
            return "";
        const p = n.properties || {};
        return p["application.name"] || n.nickname || n.description || n.name || "";
    }

    function isHeadphones(n) {
        const p = n ? (n.properties || {}) : {};
        return /head(phone|set)/i.test(String(p["device.icon-name"] || "") + " " + String(n ? n.description : ""));
    }

    function deviceIcon(n) {
        const text = String(n ? (n.name || "") + " " + (n.description || "") : "");
        if (/bluez/i.test(text))
            return Theme.glyph(0xF00AF);
        if (/hdmi|displayport/i.test(text))
            return Theme.glyph(0xF0379);
        if (isHeadphones(n))
            return Theme.glyph(0xF02CB);
        return Theme.glyph(0xF04C3);
    }

    function outputIcon() {
        if (!root.hasOutput)
            return Theme.glyph(0xEEE8);
        if (root.isHeadphones(root.sink))
            return Theme.glyph(0xF02CB);
        if (root.outputMuted || root.outputVolume <= 0)
            return Theme.glyph(0xEEE8);
        if (root.outputVolume >= 0.67)
            return Theme.glyph(0xF028);
        if (root.outputVolume >= 0.34)
            return Theme.glyph(0xF027);
        return Theme.glyph(0xF026);
    }

    // Mesmos apelidos do Omarchy (outputVolumeName), em português.
    function volumeName(volume, muted) {
        if (muted)
            return "Mudo";
        const p = Math.round(volume * 100);
        if (p === 0) return "Silêncio";
        if (p >= 100) return "Sala de concerto";
        if (p >= 85) return "Modo festa";
        if (p >= 70) return "No talo";
        if (p >= 50) return "Ritmo firme";
        if (p >= 30) return "Som ambiente";
        if (p >= 15) return "Murmúrio";
        return "Sussurro";
    }

    function percent(v) {
        return Math.round(v * 100) + "%";
    }

    PanelHero {
        width: parent.width
        icon: root.outputIcon()
        title: root.hasOutput ? root.nodeLabel(root.sink) : "Sem saída de áudio"
        meta: root.hasOutput ? root.volumeName(root.outputVolume, root.outputMuted) + " · " + root.percent(root.outputVolume) : ""

        ToggleSwitch {
            visible: root.hasOutput
            checked: !root.outputMuted
            onToggled: root.sink.audio.muted = !root.sink.audio.muted
        }
    }

    SectionHeader {
        text: "Saída"
        visible: root.hasOutput
    }

    Item {
        width: parent.width
        height: 22
        visible: root.hasOutput

        PanelSlider {
            anchors.left: parent.left
            anchors.right: outputPercent.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            value: root.outputVolume
            muted: root.outputMuted
            onMoved: v => root.sink.audio.volume = v
        }

        Text {
            id: outputPercent
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 38
            horizontalAlignment: Text.AlignRight
            text: root.percent(root.outputVolume)
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: Theme.bodySmall
        }
    }

    Column {
        width: parent.width
        spacing: 2
        visible: root.sinkRows.length > 1

        Repeater {
            model: root.sinkRows

            PanelRow {
                required property var modelData
                readonly property PwNode node: root.resolve(modelData)

                width: parent.width
                icon: root.deviceIcon(node)
                label: root.nodeLabel(node)
                selected: node !== null && root.sink !== null && node.id === root.sink.id
                onClicked: if (node) Pipewire.preferredDefaultAudioSink = node
            }
        }
    }

    SectionHeader {
        text: "Entrada"
        visible: root.source !== null && root.source.audio !== null
    }

    Item {
        width: parent.width
        height: 22
        visible: root.source !== null && root.source.audio !== null

        Text {
            id: micIcon
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 22
            text: root.source && root.source.audio && root.source.audio.muted ? Theme.glyph(0xF036D) : Theme.glyph(0xF036C)
            color: root.source && root.source.audio && root.source.audio.muted ? Theme.urgent : Theme.foreground
            font.family: Theme.font
            font.pixelSize: Theme.title

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.source.audio.muted = !root.source.audio.muted
            }
        }

        PanelSlider {
            anchors.left: micIcon.right
            anchors.leftMargin: 6
            anchors.right: inputPercent.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            value: root.source && root.source.audio ? root.source.audio.volume : 0
            muted: root.source !== null && root.source.audio !== null && root.source.audio.muted
            onMoved: v => root.source.audio.volume = v
        }

        Text {
            id: inputPercent
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 38
            horizontalAlignment: Text.AlignRight
            text: root.source && root.source.audio ? root.percent(root.source.audio.volume) : ""
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: Theme.bodySmall
        }
    }

    Column {
        width: parent.width
        spacing: 2
        visible: root.sourceRows.length > 1

        Repeater {
            model: root.sourceRows

            PanelRow {
                required property var modelData
                readonly property PwNode node: root.resolve(modelData)

                width: parent.width
                icon: Theme.glyph(0xF036C)
                label: root.nodeLabel(node)
                selected: node !== null && root.source !== null && node.id === root.source.id
                onClicked: if (node) Pipewire.preferredDefaultAudioSource = node
            }
        }
    }

    SectionHeader {
        text: "Aplicativos"
    }

    Text {
        visible: root.streamRows.length === 0
        text: "Nenhum aplicativo tocando"
        color: Theme.dim
        font.family: Theme.font
        font.pixelSize: Theme.body
    }

    Repeater {
        model: root.streamRows

        Column {
            id: streamItem

            required property var modelData
            readonly property PwNode node: root.resolve(modelData)
            readonly property bool ready: node !== null && node.audio !== null

            width: root.width
            spacing: 2

            Item {
                width: parent.width
                height: 18

                Text {
                    anchors.left: parent.left
                    anchors.right: streamPercent.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.nodeLabel(streamItem.node)
                    color: Theme.foreground
                    font.family: Theme.font
                    font.pixelSize: Theme.body
                    elide: Text.ElideRight
                }

                Text {
                    id: streamPercent
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: streamItem.ready ? (streamItem.node.audio.muted ? "mudo" : root.percent(streamItem.node.audio.volume)) : ""
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: Theme.bodySmall

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (streamItem.ready) streamItem.node.audio.muted = !streamItem.node.audio.muted
                    }
                }
            }

            PanelSlider {
                width: parent.width
                value: streamItem.ready ? streamItem.node.audio.volume : 0
                muted: streamItem.ready && streamItem.node.audio.muted
                onMoved: v => {
                    if (streamItem.ready)
                        streamItem.node.audio.volume = v;
                }
            }
        }
    }
}
