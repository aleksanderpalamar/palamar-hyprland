import QtQuick

Rectangle {
    id: root

    required property string label
    property color accent: Theme.brightForeground
    signal clicked()

    implicitWidth: 42
    implicitHeight: 42
    radius: 12
    color: pointer.containsMouse ? Theme.darkForeground : Theme.muted

    Text {
        anchors.centerIn: parent
        text: root.label
        color: root.accent
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 17
        font.weight: Font.DemiBold
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
