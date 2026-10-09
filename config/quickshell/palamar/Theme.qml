pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Cores e medidas dos painéis e da central de controle. As medidas são as da barra
// do Omarchy (shell/Commons/Style.qml); as cores vêm do tema atual, que o hypr-theme
// grava em ~/.local/state/hypr-theme/quickshell.json. Sem o arquivo, fica o Tokyo Night.
Singleton {
    id: root

    property var palette: ({})

    function reload() {
        themeFile.reload();
    }

    FileView {
        id: themeFile
        path: Quickshell.env("HOME") + "/.local/state/hypr-theme/quickshell.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.palette = JSON.parse(text());
            } catch (e) {
                console.warn("Theme: quickshell.json inválido:", e);
            }
        }
    }

    function pick(key, fallback) {
        return root.palette[key] || fallback;
    }

    readonly property bool light: pick("mode", "dark") === "light"
    readonly property color background: pick("background", "#1a1b26")
    readonly property color lighterBackground: pick("lighterBackground", "#24283b")
    readonly property color foreground: pick("foreground", "#a9b1d6")
    readonly property color brightForeground: pick("brightForeground", "#c0caf5")
    readonly property color darkForeground: pick("darkForeground", "#565f89")
    readonly property color accent: pick("accent", "#7aa2f7")
    readonly property color selection: pick("selection", "#292e42")
    readonly property color muted: pick("muted", "#414868")
    readonly property color urgent: pick("red", "#f7768e")
    readonly property color cyan: pick("cyan", "#0db9d7")
    readonly property color dim: Qt.darker(foreground, 1.4)

    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property int caption: 10
    readonly property int bodySmall: 11
    readonly property int body: 12
    readonly property int title: 14
    readonly property int display: 24

    readonly property int barHeight: 26
    readonly property int gap: 5
    readonly property int padding: 14
    readonly property int rowHeight: 28

    // Estados dos controles: tudo deriva da cor do texto, como no Omarchy.
    readonly property color normalFill: alpha(foreground, 0.04)
    readonly property color hoverFill: alpha(foreground, 0.08)
    readonly property color selectedFill: alpha(foreground, 0.18)
    readonly property color normalBorder: alpha(foreground, 0.4)
    readonly property color hoverBorder: alpha(foreground, 0.25)

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    function glyph(codepoint) {
        return String.fromCodePoint(codepoint);
    }
}
