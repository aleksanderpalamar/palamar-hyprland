import QtQuick

// Linha clicável das listas (dispositivos, saídas, conexões).
Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property string detail: ""
    property bool selected: false
    property bool clickable: true
    signal clicked()

    implicitWidth: 300
    implicitHeight: Theme.rowHeight
    color: selected ? Theme.selectedFill : (mouse.containsMouse && clickable ? Theme.hoverFill : "transparent")
    border.width: selected || (mouse.containsMouse && clickable) ? 1 : 0
    border.color: selected ? Theme.foreground : Theme.hoverBorder

    Text {
        id: iconText
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        width: 18
        text: root.icon
        color: Theme.foreground
        font.family: Theme.font
        font.pixelSize: Theme.title
    }

    Text {
        anchors.left: iconText.right
        anchors.leftMargin: 8
        anchors.right: detailText.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: root.clickable ? Theme.foreground : Theme.dim
        font.family: Theme.font
        font.pixelSize: Theme.body
        font.bold: root.selected
        elide: Text.ElideRight
    }

    Text {
        id: detailText
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: root.detail
        color: Theme.dim
        font.family: Theme.font
        font.pixelSize: Theme.bodySmall
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (root.clickable) root.clicked()
    }
}
