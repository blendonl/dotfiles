import QtQuick

Column {
    required property var items
    required property real maxKeyWidth

    spacing: 4

    Repeater {
        model: items

        KeyPair {
            required property var modelData
            item: modelData
            keyWidth: maxKeyWidth
        }
    }
}
