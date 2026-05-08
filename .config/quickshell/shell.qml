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

        function show(submap: string, payloadPath: string): void {
            root.currentSubmap = submap;
            payloadFile.path = payloadPath;
            payloadFile.reload();
        }

        function hide(): void {
            root.panelVisible = false;
        }
    }

    FileView {
        id: payloadFile
        onLoaded: {
            try {
                root.indicatorData = JSON.parse(payloadFile.text());
                root.panelVisible = true;
            } catch (e) {
                console.error("Failed to parse indicator payload:", e);
            }
        }
        onLoadFailed: function(err) {
            console.error("Failed to read indicator payload:", err);
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
