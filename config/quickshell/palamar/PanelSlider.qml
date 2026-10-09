import QtQuick

// Controle deslizante dos painéis: trilho fino e bolinha na cor do texto.
Item {
    id: root

    property real value: 0
    property real maximum: 1
    property bool muted: false
    signal moved(real value)

    readonly property real progress: maximum > 0 ? Math.max(0, Math.min(1, value / maximum)) : 0

    implicitWidth: 200
    implicitHeight: 22

    function setFromX(x) {
        const clamped = Math.max(0, Math.min(track.width, x));
        root.moved(Math.round((clamped / track.width) * root.maximum * 100) / 100);
    }

    Rectangle {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: knob.width / 2
        anchors.rightMargin: knob.width / 2
        anchors.verticalCenter: parent.verticalCenter
        height: 4
        radius: 2
        color: Theme.selectedFill

        Rectangle {
            height: parent.height
            radius: parent.radius
            width: parent.width * root.progress
            color: root.muted ? Theme.dim : Theme.foreground
        }
    }

    Rectangle {
        id: knob
        width: 14
        height: 14
        radius: 7
        anchors.verticalCenter: parent.verticalCenter
        x: track.x + track.width * root.progress - width / 2
        color: root.muted ? Theme.dim : Theme.foreground
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => root.setFromX(mouse.x - track.x)
        onPositionChanged: mouse => {
            if (pressed)
                root.setFromX(mouse.x - track.x);
        }
        onWheel: wheel => {
            const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
            root.moved(Math.max(0, Math.min(root.maximum, Math.round((root.value + step) * 100) / 100)));
        }
    }
}
