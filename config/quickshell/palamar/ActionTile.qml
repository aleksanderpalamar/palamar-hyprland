import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    required property string icon
    required property string title
    property string subtitle: ""
    signal clicked()

    implicitHeight: 72
    radius: 14
    color: pointer.containsMouse ? Theme.muted : Theme.lighterBackground
    border.width: 1
    border.color: pointer.containsMouse ? Theme.accent : Theme.muted

    Behavior on color {
        ColorAnimation { duration: 120 }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Text {
            text: root.icon
            color: Theme.accent
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 24
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: root.title
                color: Theme.brightForeground
                font.family: "Noto Sans"
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }

            Text {
                text: root.subtitle
                visible: text.length > 0
                color: Theme.foreground
                font.family: "Noto Sans"
                font.pixelSize: 11
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
