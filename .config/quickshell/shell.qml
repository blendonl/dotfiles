import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

ShellRoot {
    id: root

    property string currentSubmap: ""
    property var indicatorData: []
    property bool panelVisible: false

    IpcHandler {
        target: "indicator"

        function showSubmap(submap: string): void {
            var filePath = Quickshell.env("HOME") + "/.config/quickshell/indicators/" + submap + ".json";
            fileReader.path = filePath;
            fileReader.reload();
            root.currentSubmap = submap;
        }

        function hide(): void {
            root.panelVisible = false;
        }
    }

    FileView {
        id: fileReader
        path: ""

        onLoaded: {
            try {
                root.indicatorData = JSON.parse(fileReader.text());
                root.panelVisible = true;
            } catch (e) {
                console.error("Failed to parse indicator JSON:", e);
            }
        }

        onLoadFailed: function(error) {
            console.error("Failed to load indicator file:", error);
        }
    }

    Variants {
        model: Quickshell.screens

        IndicatorWindow {
            required property var modelData

            screen: modelData
            visible: root.panelVisible && Hyprland.focusedMonitor !== null && Hyprland.focusedMonitor.name === modelData.name
            indicatorData: root.indicatorData
        }
    }
}
