import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland

PanelWindow {
    id: root

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "#cc000000"
    exclusionMode: ExclusionMode.Ignore
    focusable: true

    // ── state ──
    property var tasks: []
    property int selectedIndex: 0
    property string statusFilter: ""
    property string priorityFilter: ""
    property bool legendVisible: false
    property bool filterPrefix: false
    property string searchText: ""
    property bool searchVisible: false

    // ── filter prefix timeout ──
    Timer {
        id: filterTimer
        interval: 800
        onTriggered: filterPrefix = false
    }

    // ── helpers ──
    function priColor(p) {
        switch (p) {
            case "URGENT": return "#ff6b6b";
            case "HIGH":   return "#ffa726";
            case "LOW":    return "#66bb6a";
            default:       return "#4ecdc4";
        }
    }
    function priBg(p) {
        switch (p) {
            case "URGENT": return "#1a0f0f";
            case "HIGH":   return "#1a140a";
            case "LOW":    return "#0a1a0f";
            default:       return "#0a1a1a";
        }
    }
    function priBorder(p) {
        switch (p) {
            case "URGENT": return "#3f1f1f";
            case "HIGH":   return "#3f2f1a";
            case "LOW":    return "#1f3f1f";
            default:       return "#1f3f3f";
        }
    }
    function statColor(s) {
        switch (s) {
            case "TODO":        return "#82aaff";
            case "IN_PROGRESS": return "#ffcb6b";
            case "IN_REVIEW":   return "#c792ea";
            case "DONE":        return "#66bb6a";
            case "FAILED":      return "#ff6b6b";
            default:            return "#888888";
        }
    }
    function statBg(s) {
        switch (s) {
            case "TODO":        return "#0a0a1a";
            case "IN_PROGRESS": return "#1a140a";
            case "IN_REVIEW":   return "#0f0a1a";
            case "DONE":        return "#0a1a0f";
            case "FAILED":      return "#1a0f0f";
            default:            return "#0a0a0a";
        }
    }
    function statBorder(s) {
        switch (s) {
            case "TODO":        return "#1f1f3f";
            case "IN_PROGRESS": return "#3f2f1a";
            case "IN_REVIEW":   return "#2f1f3f";
            case "DONE":        return "#1f3f1f";
            case "FAILED":      return "#3f1f1f";
            default:            return "#2a2a2a";
        }
    }
    function formatDue(d) {
        if (!d) return "";
        // show just the date part
        return d.substring(0, 10);
    }
    function formatEst(m) {
        if (!m && m !== 0) return "";
        if (m >= 60) {
            var h = Math.floor(m / 60);
            var rem = m % 60;
            if (rem === 0) return h + "h";
            return h + "h " + rem + "m";
        }
        return m + "m";
    }
    function projectSlug() {
        if (tasks.length > 0 && tasks[0].projectSlug) {
            return tasks[0].projectSlug;
        }
        return "";
    }
    function filteredCount() {
        return tasks.length;
    }
    function activeFilterLabel() {
        var parts = [];
        if (statusFilter) parts.push("status: " + statusFilter);
        if (priorityFilter) parts.push("priority: " + priorityFilter);
        return parts.join("  ");
    }

    // ── load tasks ──
    function loadTasks() {
        var filterArgs = "";
        if (statusFilter) filterArgs += " --status " + statusFilter;
        if (priorityFilter) filterArgs += " --priority " + priorityFilter;

        var cmd = "/usr/sbin/cadence task list --output json" + filterArgs;
        // pipe through jq for server-side title search
        if (searchText) {
            var escaped = searchText.replace(/"/g, '\\"');
            cmd += " | jq '[.[] | select(.title | test(\"" + escaped + "\"; \"i\"))]'";
        }
        cmd += " > /tmp/cadence-task-list.json";

        // reset path so FileView reloads even if it was already this path
        tasksFile.path = "";
        tasksProcess.command = ["bash", "-c", cmd];
        tasksProcess.running = true;
    }

    // ── cycle filters ──
    function cycleStatusFilter() {
        var states = ["", "BACKLOG", "TODO", "IN_PROGRESS", "IN_REVIEW", "DONE"];
        var idx = states.indexOf(statusFilter);
        idx = (idx + 1) % states.length;
        statusFilter = states[idx];
        selectedIndex = 0;
        loadTasks();
    }
    function cyclePriorityFilter() {
        var states = ["", "URGENT", "HIGH", "MEDIUM", "LOW"];
        var idx = states.indexOf(priorityFilter);
        idx = (idx + 1) % states.length;
        priorityFilter = states[idx];
        selectedIndex = 0;
        loadTasks();
    }
    function clearFilters() {
        statusFilter = "";
        priorityFilter = "";
        selectedIndex = 0;
        loadTasks();
    }

    // ── process ──
    Process {
        id: tasksProcess
        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                tasksFile.path = "/tmp/cadence-task-list.json";
            }
        }
    }

    FileView {
        id: tasksFile
        path: ""
        onLoaded: {
            try {
                root.tasks = JSON.parse(tasksFile.text());
                root.selectedIndex = 0;
                if (root.tasks.length > 0) {
                    popup.forceActiveFocus();
                }
            } catch (e) {
                console.error("Failed to parse task list:", e);
                root.tasks = [];
            }
        }
        onLoadFailed: function(err) {
            // ignore initial empty path
            if (path === "") return;
            console.error("Failed to read task list:", err);
            root.tasks = [];
        }
    }

    // ── backdrop click to dismiss ──
    MouseArea {
        anchors.fill: parent
        onClicked: Quickshell.execDetached(["qs", "ipc", "call", "task-list", "hide"])
    }

    // ── centered popup ──
    Rectangle {
        id: popup
        anchors.centerIn: parent
        width: 740
        height: Math.min(popupContent.implicitHeight + 36, root.height - 60)
        color: "#000000"
        border { color: "#262626"; width: 1 }
        radius: 6
        clip: true
        focus: true

        // swallow clicks
        MouseArea { anchors.fill: parent }

        Column {
            id: popupContent
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 18
            }
            spacing: 0

            // ── header ──
            Row {
                spacing: 8
                Text {
                    text: "Tasks"
                    color: "#777777"
                    font.family: "Fira Code"
                    font.pixelSize: 12
                }
                Text {
                    text: projectSlug()
                    color: "#4ecdc4"
                    font.family: "Fira Code"
                    font.pixelSize: 11
                    visible: projectSlug() !== ""
                }
            }

            // ── active filter chips ──
            Row {
                spacing: 8
                visible: statusFilter !== "" || priorityFilter !== ""
                anchors.topMargin: 6

                Rectangle {
                    visible: statusFilter !== ""
                    color: "#0a1a1a"
                    border { color: "#1f3f3f"; width: 1 }
                    radius: 3
                    height: filterStatusLabel.implicitHeight + 4
                    width: filterStatusLabel.implicitWidth + 12

                    Text {
                        id: filterStatusLabel
                        anchors.centerIn: parent
                        text: "status: " + statusFilter
                        color: "#4ecdc4"
                        font.family: "Fira Code"
                        font.pixelSize: 10
                    }
                }

                Rectangle {
                    visible: priorityFilter !== ""
                    color: "#0a1a1a"
                    border { color: "#1f3f3f"; width: 1 }
                    radius: 3
                    height: filterPriorityLabel.implicitHeight + 4
                    width: filterPriorityLabel.implicitWidth + 12

                    Text {
                        id: filterPriorityLabel
                        anchors.centerIn: parent
                        text: "priority: " + priorityFilter
                        color: "#4ecdc4"
                        font.family: "Fira Code"
                        font.pixelSize: 10
                    }
                }
            }

            // spacing after header+filter area
            Item { height: 6; width: 1 }

            // ── search bar ──
            Row {
                visible: searchVisible
                spacing: 8
                width: parent.width
                height: searchInput.implicitHeight + 12

                Text {
                    text: "/"
                    color: "#4ecdc4"
                    font.family: "Fira Code"
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                }
                TextInput {
                    id: searchInput
                    width: parent.width - 24
                    color: "#ffffff"
                    font.family: "Fira Code"
                    font.pixelSize: 14
                    activeFocusOnPress: true
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.fill: parent
                        text: "filter by title…"
                        color: "#333333"
                        font.family: "Fira Code"
                        font.pixelSize: 14
                        visible: !searchInput.text && !searchInput.activeFocus
                    }

                    onTextChanged: {
                        searchText = text;
                    }

                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Escape) {
                            event.accepted = true;
                            searchText = "";
                            searchInput.text = "";
                            searchVisible = false;
                            selectedIndex = 0;
                            loadTasks();
                            popup.forceActiveFocus();
                            return;
                        }
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            event.accepted = true;
                            selectedIndex = 0;
                            loadTasks();
                            popup.forceActiveFocus();
                            return;
                        }
                    }
                }
            }

            // spacing after search
            Item { height: searchVisible ? 6 : 10; width: 1 }

            // ── column headers ──
            Rectangle {
                width: parent.width
                height: colHeaderRow.implicitHeight + 8
                color: "#000000"

                Row {
                    id: colHeaderRow
                    anchors { left: parent.left; top: parent.top; topMargin: 4 }
                    spacing: 0

                    Text {
                        text: "Slug"
                        color: "#444444"
                        font.family: "Fira Code"
                        font.pixelSize: 10
                        width: 80
                    }
                    Text {
                        text: "Title"
                        color: "#444444"
                        font.family: "Fira Code"
                        font.pixelSize: 10
                        width: 260
                    }
                    Text {
                        text: "Status"
                        color: "#444444"
                        font.family: "Fira Code"
                        font.pixelSize: 10
                        width: 100
                    }
                    Text {
                        text: "Priority"
                        color: "#444444"
                        font.family: "Fira Code"
                        font.pixelSize: 10
                        width: 82
                    }
                    Text {
                        text: "Due"
                        color: "#444444"
                        font.family: "Fira Code"
                        font.pixelSize: 10
                        width: 82
                    }
                    Text {
                        text: "Est"
                        color: "#444444"
                        font.family: "Fira Code"
                        font.pixelSize: 10
                        width: 56
                    }
                }

                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: 1
                    color: "#0a0a0a"
                }
            }

            // ── task list ──
            ListView {
                id: taskList
                width: parent.width
                height: Math.min(taskList.contentHeight, 400)
                interactive: true
                clip: true
                keyNavigationEnabled: true

                model: root.tasks
                delegate: taskRowDelegate
            }

            // ── empty state ──
            Text {
                visible: root.tasks.length === 0
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "No tasks found"
                color: "#333333"
                font.family: "Fira Code"
                font.pixelSize: 13
                topPadding: 24
                bottomPadding: 24
            }

            // ── legend (toggled by ?) ──
            Rectangle {
                visible: legendVisible
                width: parent.width
                color: "#080808"
                border { color: "#1a1a1a"; width: 1 }
                radius: 4
                height: legendContent.implicitHeight + 16

                Column {
                    id: legendContent
                    anchors { left: parent.left; top: parent.top; margins: 12; right: parent.right }
                    spacing: 3

                    Text {
                        text: "Shortcuts"
                        color: "#555555"
                        font.family: "Fira Code"
                        font.pixelSize: 10
                    }
                    Row {
                        spacing: 20
                        Column {
                            spacing: 3
                            Text {
                                text: "jk  ↑↓    navigate"
                                color: "#666666"
                                font.family: "Fira Code"
                                font.pixelSize: 11
                            }
                            Text {
                                text: "Enter      open task"
                                color: "#4ecdc4"
                                font.family: "Fira Code"
                                font.pixelSize: 11
                            }
                            Text { text: ""; height: 1 }
                            Text {
                                text: "^N         new task"
                                color: "#555555"
                                font.family: "Fira Code"
                                font.pixelSize: 11
                            }
                            Text {
                                text: "Esc        close"
                                color: "#555555"
                                font.family: "Fira Code"
                                font.pixelSize: 11
                            }
                        }
                        Column {
                            spacing: 3
                            Text {
                                text: "f s        status filter"
                                color: "#666666"
                                font.family: "Fira Code"
                                font.pixelSize: 11
                            }
                            Text {
                                text: "f p        priority filter"
                                color: "#666666"
                                font.family: "Fira Code"
                                font.pixelSize: 11
                            }
                            Text {
                                text: "f c        clear filters"
                                color: "#666666"
                                font.family: "Fira Code"
                                font.pixelSize: 11
                            }
                            Text { text: ""; height: 1 }
                            Text {
                                text: "/          search title"
                                color: "#666666"
                                font.family: "Fira Code"
                                font.pixelSize: 11
                            }
                            Text {
                                text: "?          toggle help"
                                color: "#555555"
                                font.family: "Fira Code"
                                font.pixelSize: 11
                            }
                        }
                    }
                }
            }

            // ── divider ──
            Rectangle {
                width: parent.width
                height: 1
                color: "#111111"
                anchors.topMargin: legendVisible ? 0 : 0
            }

            // ── footer ──
            Rectangle {
                width: parent.width
                height: 1
                color: "#111111"
            }

            RowLayout {
                width: parent.width
                spacing: 16

                // count
                Text {
                    text: filteredCount() + " tasks"
                    color: "#555555"
                    font.family: "Fira Code"
                    font.pixelSize: 11
                }

                // filter prefix indicator
                Text {
                    visible: filterPrefix
                    text: "f…"
                    color: "#4ecdc4"
                    font.family: "Fira Code"
                    font.pixelSize: 11
                }

                Item { Layout.fillWidth: true }

                // Enter hint
                Row {
                    spacing: 6
                    Text {
                        text: "⏎"
                        color: "#4ecdc4"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                    Text {
                        text: "open"
                        color: "#4ecdc4"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                }

                // ^N hint
                Row {
                    spacing: 6
                    Rectangle {
                        color: "#111111"
                        border { color: "#2a2a2a"; width: 1 }
                        radius: 2
                        height: newKeyLabel.implicitHeight + 2
                        width: newKeyLabel.implicitWidth + 8
                        Text {
                            id: newKeyLabel
                            anchors.centerIn: parent
                            text: "^N"
                            color: "#777777"
                            font.family: "Fira Code"
                            font.pixelSize: 10
                        }
                    }
                    Text {
                        text: "new"
                        color: "#444444"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                }

                // / search hint
                Row {
                    spacing: 6
                    Rectangle {
                        color: "#111111"
                        border { color: "#2a2a2a"; width: 1 }
                        radius: 2
                        height: slashKeyLabel.implicitHeight + 2
                        width: slashKeyLabel.implicitWidth + 8
                        Text {
                            id: slashKeyLabel
                            anchors.centerIn: parent
                            text: "/"
                            color: "#777777"
                            font.family: "Fira Code"
                            font.pixelSize: 10
                        }
                    }
                    Text {
                        text: "search"
                        color: "#444444"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                }

                // filter hint
                Row {
                    spacing: 6
                    Rectangle {
                        color: "#111111"
                        border { color: "#2a2a2a"; width: 1 }
                        radius: 2
                        height: filterKeyLabel.implicitHeight + 2
                        width: filterKeyLabel.implicitWidth + 8
                        Text {
                            id: filterKeyLabel
                            anchors.centerIn: parent
                            text: "f s"
                            color: "#777777"
                            font.family: "Fira Code"
                            font.pixelSize: 10
                        }
                    }
                    Text {
                        text: "filter"
                        color: "#444444"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                }

                // ? hint
                Row {
                    spacing: 6
                    Rectangle {
                        color: "#111111"
                        border { color: "#2a2a2a"; width: 1 }
                        radius: 2
                        height: helpKeyLabel.implicitHeight + 2
                        width: helpKeyLabel.implicitWidth + 8
                        Text {
                            id: helpKeyLabel
                            anchors.centerIn: parent
                            text: "?"
                            color: "#777777"
                            font.family: "Fira Code"
                            font.pixelSize: 10
                        }
                    }
                    Text {
                        text: "help"
                        color: "#444444"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                }

                // Esc hint
                Row {
                    spacing: 6
                    Text {
                        text: "close"
                        color: "#444444"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                    Rectangle {
                        color: "#111111"
                        border { color: "#2a2a2a"; width: 1 }
                        radius: 2
                        height: escLabel.implicitHeight + 2
                        width: escLabel.implicitWidth + 8
                        Text {
                            id: escLabel
                            anchors.centerIn: parent
                            text: "Esc"
                            color: "#777777"
                            font.family: "Fira Code"
                            font.pixelSize: 10
                        }
                    }
                }
            }
        }

        // ── keyboard handling ──
        Keys.onPressed: function(event) {
            // filter prefix armed — handle s/p/c
            if (filterPrefix) {
                filterTimer.restart();
                if (event.key === Qt.Key_S) {
                    event.accepted = true;
                    filterPrefix = false;
                    cycleStatusFilter();
                    return;
                }
                if (event.key === Qt.Key_P) {
                    event.accepted = true;
                    filterPrefix = false;
                    cyclePriorityFilter();
                    return;
                }
                if (event.key === Qt.Key_C) {
                    event.accepted = true;
                    filterPrefix = false;
                    clearFilters();
                    return;
                }
                // any other key cancels prefix
                filterPrefix = false;
            }

            // j / Down — move selection down
            if (event.key === Qt.Key_J || event.key === Qt.Key_Down) {
                event.accepted = true;
                if (root.tasks.length > 0) {
                    root.selectedIndex = Math.min(root.selectedIndex + 1, root.tasks.length - 1);
                }
                return;
            }

            // k / Up — move selection up
            if (event.key === Qt.Key_K || event.key === Qt.Key_Up) {
                event.accepted = true;
                if (root.tasks.length > 0) {
                    root.selectedIndex = Math.max(root.selectedIndex - 1, 0);
                }
                return;
            }

            // Enter — open (placeholder)
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                event.accepted = true;
                return;
            }

            // Escape — clear search, then close
            if (event.key === Qt.Key_Escape) {
                event.accepted = true;
                if (searchVisible) {
                    searchText = "";
                    searchInput.text = "";
                    searchVisible = false;
                    selectedIndex = 0;
                    loadTasks();
                    return;
                }
                Quickshell.execDetached(["qs", "ipc", "call", "task-list", "hide"]);
                return;
            }

            // ? — toggle legend
            if (event.key === Qt.Key_Question) {
                event.accepted = true;
                legendVisible = !legendVisible;
                return;
            }

            // / — search
            if (event.key === Qt.Key_Slash) {
                event.accepted = true;
                searchVisible = true;
                searchInput.text = "";
                searchText = "";
                searchInput.forceActiveFocus();
                return;
            }

            // f — arm filter prefix
            if (event.key === Qt.Key_F) {
                event.accepted = true;
                filterPrefix = true;
                filterTimer.restart();
                return;
            }

            // ^N — new task
            if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_N) {
                event.accepted = true;
                Quickshell.execDetached(["qs", "ipc", "call", "task-create", "open"]);
                return;
            }
        }
    }

    // ── task row delegate ──
    Component {
        id: taskRowDelegate

        Rectangle {
            width: taskList.width
            height: 30
            color: {
                if (index === root.selectedIndex) return "#0a1a1a";
                if (index % 2 === 0) return "#000000";
                return "#030303";
            }

            Row {
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 0

                // slug (with > prefix when selected)
                Text {
                    text: (index === root.selectedIndex ? "> " : "  ") + modelData.slug
                    color: index === root.selectedIndex ? "#4ecdc4" : "#777777"
                    font.family: "Fira Code"
                    font.pixelSize: 11
                    width: 80
                }

                // title
                Text {
                    text: modelData.title
                    color: "#cccccc"
                    font.family: "Fira Code"
                    font.pixelSize: 12
                    width: 260
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                // status tag (fixed column width)
                Item {
                    width: 100
                    height: parent.height

                    Rectangle {
                        color: statBg(modelData.status)
                        border { color: statBorder(modelData.status); width: 1 }
                        radius: 3
                        height: statusText.implicitHeight + 4
                        width: Math.min(statusText.implicitWidth + 16, 94)
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left

                        Text {
                            id: statusText
                            anchors.centerIn: parent
                            text: modelData.status
                            color: statColor(modelData.status)
                            font.family: "Fira Code"
                            font.pixelSize: 10
                        }
                    }
                }

                // priority tag (fixed column width)
                Item {
                    width: 82
                    height: parent.height

                    Rectangle {
                        color: priBg(modelData.priority)
                        border { color: priBorder(modelData.priority); width: 1 }
                        radius: 3
                        height: priorityText.implicitHeight + 4
                        width: Math.min(priorityText.implicitWidth + 16, 76)
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left

                        Text {
                            id: priorityText
                            anchors.centerIn: parent
                            text: modelData.priority
                            color: priColor(modelData.priority)
                            font.family: "Fira Code"
                            font.pixelSize: 10
                        }
                    }
                }

                // due date
                Text {
                    text: formatDue(modelData.dueDate) || "—"
                    color: modelData.dueDate ? "#82aaff" : "#333333"
                    font.family: "Fira Code"
                    font.pixelSize: 11
                    width: 82
                    leftPadding: 10
                }

                // estimate
                Text {
                    text: formatEst(modelData.estimatedMinutes) || "—"
                    color: modelData.estimatedMinutes ? "#c792ea" : "#333333"
                    font.family: "Fira Code"
                    font.pixelSize: 11
                    width: 56
                    leftPadding: 2
                }
            }

            // click to select
            MouseArea {
                anchors.fill: parent
                onClicked: root.selectedIndex = index
            }
        }
    }

    // ── focus + load on show ──
    onVisibleChanged: {
        if (visible) {
            selectedIndex = 0;
            filterPrefix = false;
            legendVisible = false;
            loadTasks();
            popup.forceActiveFocus();
        }
    }
}
