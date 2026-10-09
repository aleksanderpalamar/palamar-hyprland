import QtQuick

// Título de seção em maiúsculas, apagado, como o PanelSectionHeader do Omarchy.
Text {
    color: Theme.dim
    font.family: Theme.font
    font.pixelSize: Theme.caption
    font.bold: true
    font.capitalization: Font.AllUppercase
    topPadding: 4
}
