import QtQuick

// Cabeçalho dos painéis: ícone grande, título, linha de detalhe e um controle opcional à direita.
Item {
    id: root

    property string icon: ""
    property string title: ""
    property string meta: ""
    default property alias trailing: trailingHolder.data

    implicitWidth: 300
    implicitHeight: Math.max(iconText.implicitHeight, labels.implicitHeight, trailingHolder.height)

    Text {
        id: iconText
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.display + 6
        horizontalAlignment: Text.AlignHCenter
        text: root.icon
        color: Theme.foreground
        font.family: Theme.font
        font.pixelSize: Theme.display
    }

    Column {
        id: labels
        anchors.left: iconText.right
        anchors.leftMargin: 14
        anchors.right: trailingHolder.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            width: parent.width
            text: root.title
            color: Theme.foreground
            font.family: Theme.font
            font.pixelSize: Theme.title
            font.bold: true
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            visible: text !== ""
            text: root.meta
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: Theme.body
            elide: Text.ElideRight
        }
    }

    Item {
        id: trailingHolder
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }
}
