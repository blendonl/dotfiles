import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

ShellRoot {
    id: root

    property string currentSubmap: ""
    property var indicatorData: []
    property bool panelVisible: false
    property bool taskCreateVisible: false
    property bool taskListVisible: false
    property bool agendaVisible: false
    property bool blockCreateVisible: false
    property bool plannerVisible: false

    IpcHandler {
        target: "indicator"

        function open(submap: string, payloadPath: string): void {
            root.currentSubmap = submap;
            payloadFile.path = payloadPath;
            payloadFile.reload();
        }

        function hide(): void {
            root.panelVisible = false;
        }
    }

    IpcHandler {
        target: "task-create"

        function open(): void {
            root.taskCreateVisible = true;
        }

        function hide(): void {
            root.taskCreateVisible = false;
        }
    }

    IpcHandler {
        target: "task-list"

        function open(): void {
            root.taskListVisible = true;
        }

        function hide(): void {
            root.taskListVisible = false;
        }
    }

    IpcHandler {
        target: "agenda"

        function open(): void {
            root.agendaVisible = true;
        }

        function hide(): void {
            root.agendaVisible = false;
        }
    }

    IpcHandler {
        target: "block-create"

        function open(): void {
            root.blockCreateVisible = true;
        }

        function hide(): void {
            root.blockCreateVisible = false;
        }
    }

    IpcHandler {
        target: "planner"

        function open(): void {
            root.plannerVisible = true;
        }

        function hide(): void {
            root.plannerVisible = false;
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

    Variants {
        model: Quickshell.screens

        TaskCreateWindow {
            required property var modelData

            screen: modelData
            visible: root.taskCreateVisible && Hyprland.focusedMonitor !== null && Hyprland.focusedMonitor.name === modelData.name
        }
    }

    Variants {
        model: Quickshell.screens

        TaskListWindow {
            required property var modelData

            screen: modelData
            visible: root.taskListVisible && Hyprland.focusedMonitor !== null && Hyprland.focusedMonitor.name === modelData.name
        }
    }

    Variants {
        model: Quickshell.screens

        AgendaWindow {
            required property var modelData

            screen: modelData
            visible: root.agendaVisible && Hyprland.focusedMonitor !== null && Hyprland.focusedMonitor.name === modelData.name
        }
    }

    Variants {
        model: Quickshell.screens

        BlockCreateWindow {
            required property var modelData

            screen: modelData
            visible: root.blockCreateVisible && Hyprland.focusedMonitor !== null && Hyprland.focusedMonitor.name === modelData.name
        }
    }

    Variants {
        model: Quickshell.screens

        PlannerWindow {
            required property var modelData

            screen: modelData
            visible: root.plannerVisible && Hyprland.focusedMonitor !== null && Hyprland.focusedMonitor.name === modelData.name
        }
    }
}
