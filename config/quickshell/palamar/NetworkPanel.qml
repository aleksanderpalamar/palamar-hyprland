import QtQuick
import Quickshell
import Quickshell.Io

// Painel de rede (clique no ícone da waybar), no molde do omarchy.network:
// conexão atual, ping, perda de pacotes, tráfego, IP e gateway; lista de Wi-Fi
// quando existe placa sem fio.
Column {
    id: root

    property string align: "right"
    signal closeRequested()

    width: 380
    spacing: 10

    property string device: ""
    property string deviceType: ""
    property string connection: ""
    property string ip: ""
    property string gateway: ""
    property string dns: ""
    property string connectivity: ""
    property string speed: ""
    property real rxRate: 0
    property real txRate: 0
    property real rxTotal: 0
    property real txTotal: 0
    property real lastRx: -1
    property real lastTx: -1
    property real lastTime: 0
    property bool wifiPresent: false
    property bool wifiEnabled: false
    property var wifiRows: []
    property string pingText: "…"
    property var pingHistory: []

    readonly property bool connected: device !== ""
    readonly property bool restricted: connectivity === "limited" || connectivity === "portal"

    function formatRate(bytesPerSecond) {
        if (bytesPerSecond >= 1048576) return (bytesPerSecond / 1048576).toFixed(1) + " MB/s";
        if (bytesPerSecond >= 1024) return Math.round(bytesPerSecond / 1024) + " KB/s";
        return Math.round(bytesPerSecond) + " B/s";
    }

    function formatTotal(bytes) {
        if (bytes >= 1073741824) return (bytes / 1073741824).toFixed(2) + " GB";
        if (bytes >= 1048576) return Math.round(bytes / 1048576) + " MB";
        return Math.round(bytes / 1024) + " KB";
    }

    function wifiIcon(signal) {
        const icons = [0xF092F, 0xF091F, 0xF0922, 0xF0925, 0xF0928];
        return Theme.glyph(icons[Math.max(0, Math.min(4, Math.floor(signal / 20)))]);
    }

    function parseInfo(text) {
        let device = "", type = "", connection = "", ip = "", gateway = "", dns = [];
        let speed = "", rx = -1, tx = -1;
        for (const line of text.split("\n")) {
            const sep = line.indexOf(line.startsWith("IP4.") || line.startsWith("GENERAL.") ? ":" : "=");
            if (sep < 0)
                continue;
            const key = line.slice(0, sep);
            const value = line.slice(sep + 1).replace(/\\:/g, ":");
            if (key === "dev") {
                device = value.split(":")[0] || "";
                type = value.split(":")[1] || "";
            } else if (key === "GENERAL.CONNECTION") connection = value;
            else if (key.startsWith("IP4.ADDRESS") && ip === "") ip = value.split("/")[0];
            else if (key === "IP4.GATEWAY") gateway = value;
            else if (key.startsWith("IP4.DNS")) dns.push(value);
            else if (key === "speed") speed = value;
            else if (key === "rx") rx = Number(value);
            else if (key === "tx") tx = Number(value);
            else if (key === "conn") root.connectivity = value;
            else if (key === "wifi") root.wifiPresent = Number(value) > 0;
            else if (key === "wifiradio") root.wifiEnabled = value === "enabled";
        }

        root.device = device;
        root.deviceType = type;
        root.connection = connection;
        root.ip = ip;
        root.gateway = gateway;
        root.dns = dns.join(", ");
        root.speed = speed && Number(speed) > 0 ? speed + " Mb/s" : "";

        const now = Date.now();
        if (rx >= 0 && root.lastRx >= 0 && now > root.lastTime) {
            const seconds = (now - root.lastTime) / 1000;
            root.rxRate = Math.max(0, (rx - root.lastRx) / seconds);
            root.txRate = Math.max(0, (tx - root.lastTx) / seconds);
        }
        root.lastRx = rx;
        root.lastTx = tx;
        root.lastTime = now;
        root.rxTotal = Math.max(0, rx);
        root.txTotal = Math.max(0, tx);
    }

    function parseWifi(text) {
        const out = [];
        const seen = {};
        for (const line of text.split("\n")) {
            // IN-USE:SSID:SIGNAL:SECURITY (o nmcli escapa ":" dentro do SSID como "\:").
            const parts = line.replace(/\\:/g, "\u0001").split(":").map(p => p.replace(/\u0001/g, ":"));
            if (parts.length < 4 || parts[1] === "" || seen[parts[1]])
                continue;
            seen[parts[1]] = true;
            out.push({ active: parts[0] === "*", ssid: parts[1], signal: Number(parts[2]) || 0, secure: parts[3] !== "" && parts[3] !== "--" });
        }
        root.wifiRows = out.slice(0, 8);
    }

    function parsePing(text) {
        // Em pt_BR o ping escreve "tempo="; o processo roda com LC_ALL=C, mas aceita os dois.
        const match = text.match(/(?:time|tempo)=([0-9.]+)/);
        const history = root.pingHistory.slice(-9);
        history.push(match ? Number(match[1]) : -1);
        root.pingHistory = history;
        root.pingText = match ? Math.round(Number(match[1])) + " ms" : "sem resposta";
    }

    readonly property string packetLoss: {
        if (pingHistory.length === 0) return "…";
        const lost = pingHistory.filter(v => v < 0).length;
        return Math.round(lost * 100 / pingHistory.length) + "%";
    }

    Process {
        id: infoProcess
        command: ["sh", "-c", "line=$(nmcli -t -f DEVICE,TYPE,STATE device | awk -F: '$3 == \"connected\" && $2 != \"loopback\" { print $1 \":\" $2; exit }'); echo \"dev=$line\"; d=${line%%:*}; if [ -n \"$d\" ]; then nmcli -t -f GENERAL.CONNECTION,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS device show \"$d\"; echo \"speed=$(cat /sys/class/net/$d/speed 2>/dev/null)\"; echo \"rx=$(cat /sys/class/net/$d/statistics/rx_bytes)\"; echo \"tx=$(cat /sys/class/net/$d/statistics/tx_bytes)\"; fi; echo \"conn=$(nmcli networking connectivity)\"; echo \"wifi=$(nmcli -t -f TYPE device | grep -cx wifi)\"; echo \"wifiradio=$(nmcli radio wifi)\""]
        stdout: StdioCollector {
            onStreamFinished: root.parseInfo(text)
        }
    }

    Process {
        id: wifiProcess
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.parseWifi(text)
        }
    }

    Process {
        id: pingProcess
        command: ["env", "LC_ALL=C", "ping", "-n", "-c", "1", "-W", "1", "1.1.1.1"]
        stdout: StdioCollector {
            onStreamFinished: root.parsePing(text)
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!infoProcess.running)
                infoProcess.running = true;
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!pingProcess.running)
                pingProcess.running = true;
        }
    }

    Timer {
        interval: 10000
        running: root.wifiPresent && root.wifiEnabled
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!wifiProcess.running)
                wifiProcess.running = true;
        }
    }

    PanelHero {
        width: parent.width
        icon: {
            if (!root.connected) return Theme.glyph(0xF092E);
            if (root.deviceType === "wifi") return root.restricted ? Theme.glyph(0xF0929) : Theme.glyph(0xF0928);
            return root.restricted ? Theme.glyph(0xF0202) : Theme.glyph(0xF0200);
        }
        title: root.connected ? root.connection : "Sem conexão"
        meta: {
            if (!root.connected) return "Nenhuma rede conectada";
            if (root.restricted) return "Acesso limitado à internet";
            const kind = root.deviceType === "ethernet" ? "Cabo" : (root.deviceType === "wifi" ? "Wi-Fi" : root.deviceType);
            return [kind, root.speed, root.device].filter(s => s !== "").join(" · ");
        }

        ToggleSwitch {
            visible: root.wifiPresent
            checked: root.wifiEnabled
            onToggled: {
                Quickshell.execDetached(["nmcli", "radio", "wifi", root.wifiEnabled ? "off" : "on"]);
                root.wifiEnabled = !root.wifiEnabled;
            }
        }
    }

    Grid {
        width: parent.width
        visible: root.connected
        columns: 2
        columnSpacing: 12
        rowSpacing: 8

        Repeater {
            model: [
                ["Ping", root.pingText],
                ["Perda de pacotes", root.packetLoss],
                ["Recebendo", root.formatRate(root.rxRate)],
                ["Enviando", root.formatRate(root.txRate)],
                ["Baixado", root.formatTotal(root.rxTotal)],
                ["Enviado", root.formatTotal(root.txTotal)],
                ["Endereço IP", root.ip || "—"],
                ["Gateway", root.gateway || "—"]
            ]

            Column {
                required property var modelData

                width: (root.width - 12) / 2
                spacing: 1

                Text {
                    text: modelData[0]
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: Theme.caption
                    font.bold: true
                    font.capitalization: Font.AllUppercase
                }

                Text {
                    width: parent.width
                    text: modelData[1]
                    color: Theme.foreground
                    font.family: Theme.font
                    font.pixelSize: Theme.body
                    elide: Text.ElideRight
                }
            }
        }
    }

    SectionHeader {
        text: "Redes Wi-Fi"
        visible: root.wifiPresent && root.wifiEnabled
    }

    Column {
        width: parent.width
        spacing: 2
        visible: root.wifiPresent && root.wifiEnabled

        Repeater {
            model: root.wifiRows

            PanelRow {
                required property var modelData

                width: parent.width
                icon: root.wifiIcon(modelData.signal)
                label: modelData.ssid
                detail: modelData.active ? "conectado" : (modelData.secure ? Theme.glyph(0xF033E) : "")
                selected: modelData.active
                onClicked: {
                    if (modelData.active)
                        return;
                    // Rede salva conecta direto; rede nova com senha abre o nmtui para digitar a senha.
                    Quickshell.execDetached(["sh", "-c", "nmcli device wifi connect \"$1\" || kitty --class TUI.float -e nmtui-connect \"$1\"", "sh", modelData.ssid]);
                    root.closeRequested();
                }
            }
        }
    }

    PanelButton {
        text: "Configurações de rede"
        onClicked: {
            Quickshell.execDetached(["nm-connection-editor"]);
            root.closeRequested();
        }
    }
}
