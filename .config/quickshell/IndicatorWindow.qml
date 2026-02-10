import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var indicatorData
    property int itemsPerColumn: 5
    property int maxColumns: 4

    anchors {
        bottom: true
        left: true
        right: true
    }

    focusable: false
    exclusionMode: ExclusionMode.Ignore

    color: "#000000"

    implicitHeight: contentColumn.implicitHeight + 20

    function columnCount() {
        if (!indicatorData) return 0;
        var count = Math.ceil(indicatorData.length / itemsPerColumn);
        if (count > maxColumns) {
            count = maxColumns;
        }
        return count;
    }

    function effectiveItemsPerColumn() {
        var cols = columnCount();
        if (cols === 0) return 0;
        if (cols >= maxColumns) {
            return Math.ceil(indicatorData.length / maxColumns);
        }
        return itemsPerColumn;
    }

    function getColumnItems(colIndex: int): var {
        var perCol = effectiveItemsPerColumn();
        var start = colIndex * perCol;
        var end = Math.min(start + perCol, indicatorData.length);
        var result = [];
        for (var i = start; i < end; i++) {
            result.push(indicatorData[i]);
        }
        return result;
    }

    function getMaxKeyWidth(colIndex: int): real {
        var items = getColumnItems(colIndex);
        var maxLen = 0;
        for (var i = 0; i < items.length; i++) {
            if (items[i].key.length > maxLen) {
                maxLen = items[i].key.length;
            }
        }
        return maxLen * 15;
    }

    Column {
        id: contentColumn
        anchors.centerIn: parent
        spacing: 8

        Row {
            spacing: 30
            anchors.horizontalCenter: parent.horizontalCenter

            Repeater {
                model: root.columnCount()

                KeyColumn {
                    required property int index
                    items: root.getColumnItems(index)
                    maxKeyWidth: root.getMaxKeyWidth(index)
                }
            }
        }

        Text {
            text: "Esc - Exit"
            color: "#ffffff"
            font.family: "Fira Code"
            font.pixelSize: 18
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
