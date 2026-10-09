import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Seletor em carrossel para temas e papéis de parede, no molde do image-picker do
// Omarchy (shell/plugins/image-picker/ImagePicker.qml): a imagem escolhida aparece
// grande no centro e as vizinhas viram fatias inclinadas dos lados.
// Setas ou Tab navegam, Enter aplica, Esc fecha; clicar numa fatia seleciona e
// clicar na imagem grande aplica.
Scope {
    id: root

    property string mode: ""
    property var items: []
    property int selectedIndex: 0
    readonly property bool opened: mode !== ""
    readonly property string hyprTheme: Quickshell.env("HOME") + "/.local/bin/hypr-theme"

    readonly property int expandedWidth: 768
    readonly property int expandedHeight: 475
    readonly property int sliceWidth: 108
    readonly property int sliceHeight: 432
    readonly property int sliceSpacing: -30
    readonly property int skewOffset: 28
    readonly property int previewRadius: 6

    function open(newMode) {
        if (root.mode === newMode) {
            root.close();
            return;
        }
        root.items = [];
        root.mode = newMode;
        loader.command = [root.hyprTheme, newMode === "themes" ? "list" : "backgrounds", "--json"];
        loader.running = true;
    }

    function close() {
        root.mode = "";
    }

    function move(step) {
        if (root.items.length > 0)
            root.selectedIndex = (root.selectedIndex + step + root.items.length) % root.items.length;
    }

    function apply() {
        const item = root.items[root.selectedIndex];
        if (item)
            Quickshell.execDetached([root.hyprTheme, root.mode === "themes" ? "set" : "bg", item.key]);
        root.close();
    }

    Process {
        id: loader
        stdout: StdioCollector {
            onStreamFinished: {
                let rows = [];
                try {
                    rows = JSON.parse(text);
                } catch (e) {
                    console.warn("ImagePicker: saída inválida do hypr-theme:", e);
                }
                const themes = root.mode === "themes";
                const mapped = rows.map(r => ({
                    key: themes ? r.name : r.path,
                    label: r.label,
                    image: themes ? r.preview : r.path,
                    current: r.current
                }));
                root.selectedIndex = Math.max(0, mapped.findIndex(r => r.current));
                root.items = mapped;
            }
        }
    }

    PanelWindow {
        id: window

        visible: root.opened
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
        WlrLayershell.namespace: "quickshell-image-picker"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Rectangle {
            anchors.fill: parent
            color: Theme.alpha(Theme.background, 0.5)
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }

        Item {
            id: card

            visible: root.items.length > 0
            width: Math.min(parent.width - 80, carousel.width + 40)
            height: root.expandedHeight + 30 + 74
            anchors.centerIn: parent

            MouseArea {
                anchors.fill: parent
                onWheel: wheel => root.move(wheel.angleDelta.y > 0 ? -1 : 1)
            }

            Item {
                id: carousel

                readonly property real itemStep: root.sliceWidth + root.sliceSpacing
                readonly property real previewX: (width - root.expandedWidth) / 2

                anchors.top: parent.top
                anchors.topMargin: 30
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.expandedWidth + 13 * itemStep
                height: root.expandedHeight
                focus: true

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.close();
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.apply();
                    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) {
                        root.move(-1);
                    } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
                        root.move(1);
                    } else {
                        return;
                    }
                    event.accepted = true;
                }

                Repeater {
                    model: root.items

                    Item {
                        id: item

                        required property var modelData
                        required property int index

                        readonly property int relativeIndex: index - root.selectedIndex
                        readonly property bool selected: relativeIndex === 0
                        readonly property bool inWindow: Math.abs(relativeIndex) <= root.previewRadius

                        readonly property real skAbs: Math.abs(root.skewOffset)
                        readonly property real topLeft: skAbs
                        readonly property real topRight: width
                        readonly property real bottomRight: width - skAbs
                        readonly property real bottomLeft: 0

                        visible: inWindow
                        x: selected ? carousel.previewX : (relativeIndex < 0 ? carousel.previewX + relativeIndex * carousel.itemStep : carousel.previewX + root.expandedWidth + root.sliceSpacing + (relativeIndex - 1) * carousel.itemStep)
                        y: selected ? 0 : (root.expandedHeight - root.sliceHeight) / 2
                        z: selected ? 100 : 50 - Math.min(Math.abs(relativeIndex), 40)
                        width: selected ? root.expandedWidth : root.sliceWidth
                        height: selected ? root.expandedHeight : root.sliceHeight

                        Behavior on x { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                        Behavior on y { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                        Behavior on width { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                        Behavior on height { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

                        Item {
                            id: maskShape
                            anchors.fill: parent
                            visible: false
                            layer.enabled: true

                            Shape {
                                anchors.fill: parent
                                antialiasing: true
                                preferredRendererType: Shape.CurveRenderer

                                ShapePath {
                                    fillColor: "white"
                                    strokeColor: "transparent"
                                    startX: item.topLeft
                                    startY: 0
                                    PathLine { x: item.topRight; y: 0 }
                                    PathLine { x: item.bottomRight; y: item.height }
                                    PathLine { x: item.bottomLeft; y: item.height }
                                    PathLine { x: item.topLeft; y: 0 }
                                }
                            }
                        }

                        Item {
                            anchors.fill: parent
                            layer.enabled: true
                            layer.smooth: true
                            layer.effect: MultiEffect {
                                maskEnabled: true
                                maskSource: maskShape
                                maskThresholdMin: 0.3
                                maskSpreadAtMin: 0.3
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: Theme.background
                            }

                            Image {
                                anchors.fill: parent
                                // Só decodifica as imagens perto da seleção.
                                source: item.inWindow && item.modelData.image ? "file://" + item.modelData.image : ""
                                sourceSize.width: root.expandedWidth
                                sourceSize.height: root.expandedHeight
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                smooth: true
                                opacity: status === Image.Ready ? 1 : 0

                                Behavior on opacity { NumberAnimation { duration: 90 } }
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: Theme.alpha(Theme.background, item.selected ? 0 : 0.42)
                            }
                        }

                        Shape {
                            anchors.fill: parent
                            antialiasing: true
                            preferredRendererType: Shape.CurveRenderer

                            ShapePath {
                                fillColor: "transparent"
                                strokeColor: item.selected ? Theme.accent : Theme.alpha(Theme.foreground, 0.28)
                                strokeWidth: item.selected ? 3 : 1
                                startX: item.topLeft
                                startY: 0
                                PathLine { x: item.topRight; y: 0 }
                                PathLine { x: item.bottomRight; y: item.height }
                                PathLine { x: item.bottomLeft; y: item.height }
                                PathLine { x: item.topLeft; y: 0 }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: item.selected ? root.apply() : (root.selectedIndex = item.index)
                        }
                    }
                }
            }

            Text {
                anchors.top: carousel.bottom
                anchors.topMargin: 16
                anchors.horizontalCenter: carousel.horizontalCenter
                width: root.expandedWidth
                text: {
                    const item = root.items[root.selectedIndex];
                    return item ? item.label + (item.current ? "  (atual)" : "") : "";
                }
                color: Theme.foreground
                style: Text.Outline
                styleColor: Theme.alpha(Theme.background, 0.7)
                font.family: Theme.font
                font.pixelSize: Theme.display
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }
    }
}
