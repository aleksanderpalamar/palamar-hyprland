import QtQuick
import Quickshell

// Calendário (clique no relógio da waybar), no molde do omarchy.clock.
// A semana começa no domingo, como nos calendários brasileiros.
Column {
    id: root

    property string align: "center"
    signal closeRequested()

    width: 7 * 46
    spacing: 10

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property date today: clock.date
    property int year: today.getFullYear()
    property int month: today.getMonth()
    readonly property bool showingToday: year === today.getFullYear() && month === today.getMonth()

    function moveMonth(step) {
        const d = new Date(root.year, root.month + step, 1);
        root.year = d.getFullYear();
        root.month = d.getMonth();
    }

    function goToToday() {
        root.year = root.today.getFullYear();
        root.month = root.today.getMonth();
    }

    // 6 semanas x 7 dias, começando no domingo da semana do dia 1.
    readonly property var days: {
        const first = new Date(root.year, root.month, 1);
        const start = new Date(root.year, root.month, 1 - first.getDay());
        const out = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i);
            out.push({
                day: d.getDate(),
                inMonth: d.getMonth() === root.month,
                isToday: d.getFullYear() === root.today.getFullYear() && d.getMonth() === root.today.getMonth() && d.getDate() === root.today.getDate()
            });
        }
        return out;
    }

    PanelHero {
        width: parent.width
        icon: Theme.glyph(0xF00ED)
        title: Qt.locale("pt_BR").toString(new Date(root.year, root.month, 1), "MMMM 'de' yyyy")
        meta: "hoje, " + Qt.locale("pt_BR").toString(root.today, "dddd, d")

        Row {
            spacing: 4

            PanelButton {
                text: Theme.glyph(0xF0141)
                implicitWidth: 28
                onClicked: root.moveMonth(-1)
            }

            PanelButton {
                text: Theme.glyph(0xF0142)
                implicitWidth: 28
                onClicked: root.moveMonth(1)
            }
        }
    }

    Grid {
        id: grid
        columns: 7

        Repeater {
            model: ["D", "S", "T", "Q", "Q", "S", "S"]

            Text {
                required property var modelData

                width: 46
                height: 22
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: modelData
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: Theme.caption
                font.bold: true
            }
        }

        Repeater {
            model: root.days

            Rectangle {
                required property var modelData

                width: 46
                height: 30
                color: modelData.isToday ? Theme.selectedFill : "transparent"
                border.width: modelData.isToday ? 1 : 0
                border.color: Theme.foreground

                Text {
                    anchors.centerIn: parent
                    text: modelData.day
                    color: modelData.inMonth ? Theme.foreground : Theme.alpha(Theme.dim, 0.5)
                    font.family: Theme.font
                    font.pixelSize: Theme.body
                    font.bold: modelData.isToday
                }
            }
        }

        // Rolar o mouse sobre o calendário troca de mês.
        WheelHandler {
            onWheel: event => root.moveMonth(event.angleDelta.y > 0 ? -1 : 1)
        }
    }

    PanelButton {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: !root.showingToday
        text: "Voltar para hoje"
        onClicked: root.goToToday()
    }
}
