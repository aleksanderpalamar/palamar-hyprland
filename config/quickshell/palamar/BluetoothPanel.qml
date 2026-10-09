import QtQuick
import Quickshell
import Quickshell.Bluetooth

// Painel de bluetooth (clique no ícone da waybar), no molde do omarchy.bluetooth:
// liga/desliga o adaptador, conecta e desconecta pareados e procura novos.
Column {
    id: root

    property string align: "right"
    signal closeRequested()

    width: 380
    spacing: 10

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool enabledAdapter: adapter !== null && adapter.enabled
    readonly property var devices: adapter ? adapter.devices.values : []

    // Procura aparelhos novos só enquanto o painel está aberto.
    Component.onCompleted: if (root.enabledAdapter) root.adapter.discovering = true
    Component.onDestruction: if (root.adapter && root.adapter.discovering) root.adapter.discovering = false
    onEnabledAdapterChanged: if (root.enabledAdapter) root.adapter.discovering = true

    // Listas por endereço (texto), não pelo objeto: o aparelho pode sumir a qualquer momento.
    function rows(accept) {
        const out = [];
        for (const d of root.devices) {
            if (d && accept(d))
                out.push(String(d.address));
        }
        return out;
    }

    function resolve(address) {
        for (const d of root.devices) {
            if (d && String(d.address) === address)
                return d;
        }
        return null;
    }

    readonly property var connectedRows: rows(d => d.connected)
    readonly property var pairedRows: rows(d => !d.connected && (d.paired || d.bonded))
    readonly property var discoveredRows: rows(d => !d.connected && !d.paired && !d.bonded && d.name && d.name !== d.address.replace(/:/g, "-"))

    function deviceIcon(d) {
        const icon = String(d ? d.icon : "");
        if (/headset|headphone/.test(icon)) return Theme.glyph(0xF02CB);
        if (/phone/.test(icon)) return Theme.glyph(0xF011C);
        if (/video-display|tv/.test(icon)) return Theme.glyph(0xF0502);
        if (/keyboard/.test(icon)) return Theme.glyph(0xF030C);
        if (/mouse/.test(icon)) return Theme.glyph(0xF037D);
        if (/audio|speaker/.test(icon)) return Theme.glyph(0xF04C3);
        if (/gaming|joystick/.test(icon)) return Theme.glyph(0xF0297);
        return Theme.glyph(0xF00AF);
    }

    function detail(d) {
        if (!d) return "";
        if (d.pairing) return "pareando…";
        if (d.state === BluetoothDeviceState.Connecting) return "conectando…";
        if (d.state === BluetoothDeviceState.Disconnecting) return "desconectando…";
        if (d.connected && d.batteryAvailable) return Math.round(d.battery * 100) + "%";
        return "";
    }

    PanelHero {
        width: parent.width
        icon: !root.adapter ? Theme.glyph(0xF00B2) : (!root.enabledAdapter ? Theme.glyph(0xF00B2) : (root.connectedRows.length > 0 ? Theme.glyph(0xF00B1) : Theme.glyph(0xF00AF)))
        title: "Bluetooth"
        meta: {
            if (!root.adapter) return "Nenhum adaptador encontrado";
            if (!root.enabledAdapter) return "Desligado";
            if (root.connectedRows.length === 1) return "1 aparelho conectado";
            if (root.connectedRows.length > 1) return root.connectedRows.length + " aparelhos conectados";
            return root.adapter.discovering ? "Procurando aparelhos…" : "Ligado";
        }

        ToggleSwitch {
            visible: root.adapter !== null
            checked: root.enabledAdapter
            onToggled: root.adapter.enabled = !root.adapter.enabled
        }
    }

    SectionHeader {
        text: "Conectados"
        visible: root.enabledAdapter && root.connectedRows.length > 0
    }

    Column {
        width: parent.width
        spacing: 2
        visible: root.enabledAdapter

        Repeater {
            model: root.connectedRows

            PanelRow {
                required property var modelData
                readonly property BluetoothDevice device: root.resolve(modelData)

                width: parent.width
                icon: root.deviceIcon(device)
                label: device ? device.name : modelData
                detail: root.detail(device)
                selected: true
                onClicked: if (device) device.disconnect()
            }
        }
    }

    SectionHeader {
        text: "Pareados"
        visible: root.enabledAdapter && root.pairedRows.length > 0
    }

    Column {
        width: parent.width
        spacing: 2
        visible: root.enabledAdapter

        Repeater {
            model: root.pairedRows

            PanelRow {
                required property var modelData
                readonly property BluetoothDevice device: root.resolve(modelData)

                width: parent.width
                icon: root.deviceIcon(device)
                label: device ? device.name : modelData
                detail: root.detail(device)
                onClicked: if (device) device.connect()
            }
        }
    }

    SectionHeader {
        text: "Disponíveis"
        visible: root.enabledAdapter
    }

    Text {
        visible: root.enabledAdapter && root.discoveredRows.length === 0
        text: root.adapter && root.adapter.discovering ? "Procurando…" : "Nenhum aparelho novo"
        color: Theme.dim
        font.family: Theme.font
        font.pixelSize: Theme.body
    }

    Column {
        width: parent.width
        spacing: 2
        visible: root.enabledAdapter

        Repeater {
            // Limita a lista: em lugar movimentado aparecem dezenas de aparelhos.
            model: root.discoveredRows.slice(0, 8)

            PanelRow {
                required property var modelData
                readonly property BluetoothDevice device: root.resolve(modelData)

                width: parent.width
                icon: root.deviceIcon(device)
                label: device ? device.name : modelData
                detail: root.detail(device) || "parear"
                onClicked: {
                    if (!device)
                        return;
                    device.trusted = true;
                    device.pair();
                }
            }
        }
    }
}
