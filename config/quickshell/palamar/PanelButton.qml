import QtQuick

// Botão de texto com borda, como o PanelActionButton do Omarchy.
Rectangle {
    id: root

    property string text: ""
    signal clicked()

    implicitWidth: label.implicitWidth + 24
    implicitHeight: Theme.rowHeight
    color: mouse.containsMouse ? Theme.hoverFill : Theme.normalFill
    border.width: 1
    border.color: mouse.containsMouse ? Theme.foreground : Theme.normalBorder

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: Theme.foreground
        font.family: Theme.font
        font.pixelSize: Theme.body
        font.bold: true
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
