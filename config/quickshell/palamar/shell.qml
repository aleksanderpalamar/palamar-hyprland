//@ pragma ShellId palamar-control-center
//@ pragma IconTheme Yaru-magenta
//@ pragma NativeTextRendering

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    property bool opened: false
    property string volumeText: "--"
    property string connectionText: "Verificando..."
    property string memoryText: "--"
    property string diskText: "--"
    property string loadText: "--"

    function refresh(): void {
        if (!volumeProcess.running)
            volumeProcess.running = true;
        if (!networkProcess.running)
            networkProcess.running = true;
        if (!systemProcess.running)
            systemProcess.running = true;
    }

    function closeAndRun(command: list<string>): void {
        opened = false;
        Quickshell.execDetached(command);
    }

    function runAndRefresh(command: list<string>): void {
        Quickshell.execDetached(command);
        delayedRefresh.restart();
    }

    // Painéis da waybar (som, bluetooth, rede, tela, calendário), como os da barra do Omarchy.
    // A waybar chama: qs ipc -c palamar call panels toggle <nome>
    property string activePanel: ""
    readonly property var panelFiles: ({
        audio: "AudioPanel.qml",
        bluetooth: "BluetoothPanel.qml",
        network: "NetworkPanel.qml",
        display: "DisplayPanel.qml",
        calendar: "CalendarPanel.qml"
    })

    onActivePanelChanged: {
        if (activePanel !== "")
            opened = false;
    }

    onOpenedChanged: {
        if (opened)
            activePanel = "";
    }

    IpcHandler {
        target: "panels"

        function toggle(name: string): void {
            if (!(name in root.panelFiles))
                return;
            root.activePanel = root.activePanel === name ? "" : name;
        }

        function close(): void {
            root.activePanel = "";
        }
    }

    // Seletor de tema e de papel de parede (SUPER + SHIFT + CTRL + ESPAÇO / SUPER + CTRL + ESPAÇO).
    ImagePicker {
        id: picker
    }

    IpcHandler {
        target: "picker"

        function themes(): void {
            root.opened = false;
            root.activePanel = "";
            picker.open("themes");
        }

        function backgrounds(): void {
            root.opened = false;
            root.activePanel = "";
            picker.open("backgrounds");
        }

        function close(): void {
            picker.close();
        }
    }

    // O hypr-theme chama isto depois de gravar as cores novas.
    IpcHandler {
        target: "theme"

        function reload(): void {
            Theme.reload();
        }
    }

    IpcHandler {
        target: "controlCenter"

        function toggle(): void {
            root.opened = !root.opened;
            if (root.opened)
                root.refresh();
        }

        function show(): void {
            root.opened = true;
            root.refresh();
        }

        function hide(): void {
            root.opened = false;
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Process {
        id: volumeProcess
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{ if ($0 ~ /MUTED/) { print \"Mudo\" } else { printf \"%d%%\\n\", $2 * 100 } }'"]
        stdout: StdioCollector {
            onStreamFinished: root.volumeText = text.trim()
        }
    }

    Process {
        id: networkProcess
        command: ["sh", "-c", "value=$(nmcli -t -f STATE,CONNECTION device | awk -F: '$1 == \"connected\" { print $2; exit }'); printf '%s\\n' \"${value:-Sem rede}\""]
        stdout: StdioCollector {
            onStreamFinished: root.connectionText = text.trim()
        }
    }

    Process {
        id: systemProcess
        command: ["sh", "-c", "mem=$(free -h | awk '/^Mem:/ { print $3 \" de \" $2 }'); disk=$(df -h / | awk 'NR == 2 { print $5 \" usado\" }'); load=$(cut -d ' ' -f1 /proc/loadavg); printf '%s|%s|%s\\n' \"$mem\" \"$disk\" \"$load\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const values = text.trim().split("|");
                root.memoryText = values.length > 0 ? values[0] : "--";
                root.diskText = values.length > 1 ? values[1] : "--";
                root.loadText = values.length > 2 ? values[2] : "--";
            }
        }
    }

    Timer {
        interval: 4000
        running: root.opened
        repeat: true
        onTriggered: root.refresh()
    }

    Timer {
        id: delayedRefresh
        interval: 250
        repeat: false
        onTriggered: root.refresh()
    }

    PanelWindow {
        id: panel
        visible: root.opened
        color: "transparent"
        implicitWidth: 400
        implicitHeight: 610
        exclusionMode: ExclusionMode.Ignore
        aboveWindows: true
        focusable: false

        anchors {
            top: true
            right: true
        }

        margins {
            top: 48
            right: 12
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-control-center"

        Rectangle {
            anchors.fill: parent
            radius: 22
            color: Theme.alpha(Theme.background, 0.95)
            border.width: 1
            border.color: Theme.alpha(Theme.accent, 0.44)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 0

                        Text {
                            text: Qt.formatDateTime(clock.date, "HH:mm")
                            color: Theme.brightForeground
                            font.family: "Noto Sans"
                            font.pixelSize: 32
                            font.weight: Font.Bold
                        }

                        Text {
                            text: Qt.locale("pt_BR").toString(clock.date, "dddd, dd 'de' MMMM")
                            color: Theme.foreground
                            font.family: "Noto Sans"
                            font.pixelSize: 12
                        }
                    }

                    Item { Layout.fillWidth: true }

                    RoundButton {
                        label: "×"
                        onClicked: root.opened = false
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 94
                    radius: 16
                    color: Theme.lighterBackground
                    border.width: 1
                    border.color: Theme.muted

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        Text {
                            text: root.volumeText === "Mudo" ? "󰝟" : "󰕾"
                            color: root.volumeText === "Mudo" ? Theme.urgent : Theme.cyan
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 27
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: "Áudio"
                                color: Theme.brightForeground
                                font.family: "Noto Sans"
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: root.volumeText
                                color: Theme.foreground
                                font.family: "Noto Sans"
                                font.pixelSize: 12
                            }
                        }

                        RoundButton {
                            label: "−"
                            onClicked: root.runAndRefresh(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"])
                        }

                        RoundButton {
                            label: "󰝟"
                            accent: Theme.urgent
                            onClicked: root.runAndRefresh(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
                        }

                        RoundButton {
                            label: "+"
                            onClicked: root.runAndRefresh(["wpctl", "set-volume", "-l", "1", "@DEFAULT_AUDIO_SINK@", "5%+"])
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 10
                    rowSpacing: 10

                    ActionTile {
                        Layout.fillWidth: true
                        icon: "󰕾"
                        title: "Saída de áudio"
                        subtitle: root.volumeText
                        onClicked: root.closeAndRun(["/home/palamar/.local/bin/waybar-audio-output"])
                    }

                    ActionTile {
                        Layout.fillWidth: true
                        icon: ""
                        title: "Bluetooth"
                        subtitle: "Gerenciar dispositivos"
                        onClicked: root.closeAndRun(["blueman-manager"])
                    }

                    ActionTile {
                        Layout.fillWidth: true
                        icon: "󰈀"
                        title: "Rede"
                        subtitle: root.connectionText
                        onClicked: root.closeAndRun(["nm-connection-editor"])
                    }

                    ActionTile {
                        Layout.fillWidth: true
                        icon: ""
                        title: "Arquivos"
                        subtitle: "Abrir Nautilus"
                        onClicked: root.closeAndRun(["nautilus"])
                    }

                    ActionTile {
                        Layout.fillWidth: true
                        icon: ""
                        title: "Terminal"
                        subtitle: "Kitty"
                        onClicked: root.closeAndRun(["kitty"])
                    }

                    ActionTile {
                        Layout.fillWidth: true
                        icon: ""
                        title: "Bloquear"
                        subtitle: "Bloquear a sessão"
                        onClicked: root.closeAndRun(["sh", "-c", "pidof hyprlock || hyprlock"])
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 96
                    radius: 16
                    color: Theme.lighterBackground
                    border.width: 1
                    border.color: Theme.muted

                    GridLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        columns: 3
                        columnSpacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text { text: "Memória"; color: Theme.foreground; font.family: "Noto Sans"; font.pixelSize: 11 }
                            Text { text: root.memoryText; color: Theme.brightForeground; font.family: "Noto Sans"; font.pixelSize: 13; font.weight: Font.DemiBold }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text { text: "Disco"; color: Theme.foreground; font.family: "Noto Sans"; font.pixelSize: 11 }
                            Text { text: root.diskText; color: Theme.brightForeground; font.family: "Noto Sans"; font.pixelSize: 13; font.weight: Font.DemiBold }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text { text: "Carga"; color: Theme.foreground; font.family: "Noto Sans"; font.pixelSize: 11 }
                            Text { text: root.loadText; color: Theme.brightForeground; font.family: "Noto Sans"; font.pixelSize: 13; font.weight: Font.DemiBold }
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "SUPER+ALT+ESPAÇO para abrir ou fechar"
                    color: Theme.darkForeground
                    font.family: "Noto Sans"
                    font.pixelSize: 11
                }
            }
        }
    }

    PanelWindow {
        id: popupLayer

        visible: root.activePanel !== ""
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: true

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-panel"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        // A faixa da barra fica de fora da camada: clicar de novo no ícone chega
        // na waybar, que manda o "toggle" e fecha o painel.
        mask: Region {
            y: Theme.barHeight
            width: popupLayer.width
            height: Math.max(0, popupLayer.height - Theme.barHeight)
        }

        // Clique fora do cartão fecha o painel.
        MouseArea {
            anchors.fill: parent
            onClicked: root.activePanel = ""
        }

        Rectangle {
            id: card

            readonly property int maxHeight: popupLayer.height - Theme.barHeight - Theme.gap * 2
            readonly property string align: panelLoader.item && panelLoader.item.align ? panelLoader.item.align : "right"

            x: align === "center" ? Math.round((popupLayer.width - width) / 2) : popupLayer.width - width - Theme.gap
            y: Theme.barHeight + Theme.gap
            width: (panelLoader.item ? panelLoader.item.width : 380) + Theme.padding * 2 + 4
            height: Math.min(maxHeight, (panelLoader.item ? panelLoader.item.implicitHeight : 0) + Theme.padding * 2 + 4)
            color: Theme.background
            border.width: 2
            border.color: Theme.accent
            opacity: 0
            focus: true

            Keys.onEscapePressed: root.activePanel = ""

            states: State {
                when: popupLayer.visible
                PropertyChanges { card.opacity: 1 }
            }

            transitions: Transition {
                NumberAnimation { property: "opacity"; duration: 140; easing.type: Easing.OutCubic }
            }

            // Engole os cliques dentro do cartão para não fecharem o painel.
            MouseArea {
                anchors.fill: parent
            }

            Flickable {
                anchors.fill: parent
                anchors.margins: Theme.padding + 2
                contentWidth: width
                contentHeight: panelLoader.item ? panelLoader.item.implicitHeight : 0
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Loader {
                    id: panelLoader
                    source: root.activePanel !== "" ? root.panelFiles[root.activePanel] : ""
                }

                Connections {
                    target: panelLoader.item
                    ignoreUnknownSignals: true

                    function onCloseRequested() {
                        root.activePanel = "";
                    }
                }
            }
        }
    }
}
