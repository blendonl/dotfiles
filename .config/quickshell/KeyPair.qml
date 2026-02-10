import QtQuick

Row {
    required property var item
    required property real keyWidth

    spacing: 0

    Text {
        text: item.key
        color: "#ffffff"
        font.family: "Fira Code"
        font.pixelSize: 22
        width: keyWidth
        horizontalAlignment: Text.AlignLeft
    }

    Text {
        text: " → "
        color: "#ffffff"
        font.family: "Fira Code"
        font.pixelSize: 22
    }

    Text {
        text: item.value
        color: "#ffffff"
        font.family: "Fira Code"
        font.pixelSize: 22
    }
}
