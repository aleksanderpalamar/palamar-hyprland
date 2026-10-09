import QtQuick

// Interruptor quadrado (o Omarchy só arredonda quando o Hyprland usa rounding).
Item {
    id: root

    property bool checked: false
    property bool busy: false
    signal toggled()

    implicitWidth: 42
    implicitHeight: 22

    Rectangle {
        id: track
        anchors.fill: parent
        color: root.checked ? Theme.selectedFill : (mouse.containsMouse ? Theme.hoverFill : Theme.normalFill)
        border.width: 1
        border.color: root.checked ? Theme.foreground : Theme.normalBorder
        opacity: root.busy ? 0.5 : 1

        Behavior on color { ColorAnimation { duration: 120 } }

        Rectangle {
            width: 16
            height: 16
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? track.width - width - 3 : 3
            color: root.checked ? Theme.foreground : Qt.darker(Theme.foreground, 1.25)

            Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (!root.busy) root.toggled()
    }
}
