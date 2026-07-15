import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
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
    property string projectFilter: ""
    property bool legendVisible: false
    property bool filterPrefix: false
    property string searchText: ""
    property bool searchVisible: false
    property bool projectFilterVisible: false

    // ── multi-select ──
    property var selectedTaskSlugs: ({})
    property bool multiSelectMode: false
    property string pendingAction: ""  // "" | "delete" | "status" | "priority"
    property int selectedCount: 0

    // ── keep selectedCount in sync (QML bindings can't trace into JS functions) ──
    onSelectedTaskSlugsChanged: {
        selectedCount = Object.keys(selectedTaskSlugs).length;
    }

    // ── multi-select pending timeout ──
    Timer {
        id: pendingActionTimer
        interval: 2000
        onTriggered: pendingAction = ""
    }

    // ── pagination ──
    property int currentPage: 1
    property int pageSize: 50
    property bool hasMore: true
    property bool isLoadingMore: false

    // ── filter prefix timeout ──
    Timer {
        id: filterTimer
        interval: 800
        onTriggered: filterPrefix = false
    }

    // ── auto-scroll list to follow keyboard selection ──
    onSelectedIndexChanged: {
        if (taskList) {
            taskList.positionViewAtIndex(selectedIndex, ListView.Contain);
        }
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
    function projectLabel() {
        if (projectFilter) return "project: " + projectFilter;
        return "all projects";
    }
    function filteredCount() {
        return tasks.length;
    }
    function activeFilterLabel() {
        var parts = [];
        if (statusFilter) parts.push("status: " + statusFilter);
        if (priorityFilter) parts.push("priority: " + priorityFilter);
        if (projectFilter) parts.push("project: " + projectFilter);
        return parts.join("  ");
    }

    // ── load tasks ──
    function loadTasks() {
        currentPage = 1;
        hasMore = true;
        isLoadingMore = false;
        _loadPage(currentPage);
    }

    function loadMoreTasks() {
        if (!hasMore || isLoadingMore || tasksProcess.running) return;
        currentPage += 1;
        isLoadingMore = true;
        _loadPage(currentPage);
    }

    function _loadPage(page) {
        var filterArgs = "";
        if (statusFilter) filterArgs += " --status " + statusFilter;
        if (priorityFilter) filterArgs += " --priority " + priorityFilter;
        if (projectFilter) filterArgs += " --project " + projectFilter;
        filterArgs += " --page " + page + " --limit " + pageSize;

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
        projectFilter = "";
        projectFilterVisible = false;
        selectedIndex = 0;
        loadTasks();
    }

    // ── multi-select helpers ──
    // IMPORTANT: always assign a fresh object to selectedTaskSlugs so QML
    // bindings (reference-equal check) see the change and re-evaluate.
    function _cloneSelection() {
        var copy = ({});
        var keys = Object.keys(selectedTaskSlugs);
        for (var i = 0; i < keys.length; i++) {
            copy[keys[i]] = true;
        }
        return copy;
    }

    function toggleTaskSelection(slug) {
        var next = _cloneSelection();
        if (next[slug]) {
            delete next[slug];
        } else {
            next[slug] = true;
        }
        selectedTaskSlugs = next;  // new object → bindings refresh
        pendingAction = "";
        if (Object.keys(next).length === 0) {
            multiSelectMode = false;
        }
    }

    function exitMultiSelect() {
        selectedTaskSlugs = ({});  // fresh empty object
        multiSelectMode = false;
        pendingAction = "";
    }

    function executeBatch(cmdBuilder) {
        var slugs = Object.keys(selectedTaskSlugs);
        if (slugs.length === 0) return;
        var cmds = slugs.map(function(s) { return cmdBuilder(s); });
        var script = cmds.join(" && ");
        batchProcess.command = ["bash", "-c", script];
        batchProcess.running = true;
    }

    function batchDelete() {
        if (pendingAction === "delete") {
            // second press — confirm and execute
            executeBatch(function(slug) {
                return "/usr/sbin/cadence task delete " + slug + " --force";
            });
            pendingAction = "";
        } else {
            pendingAction = "delete";
            pendingActionTimer.restart();
        }
    }

    function handleBatchStatusKey(text) {
        if (!text) return false;
        var map = { "T": "TODO", "I": "IN_PROGRESS", "R": "IN_REVIEW", "D": "DONE", "B": "BACKLOG" };
        var status = map[text.toUpperCase()];
        if (status) {
            executeBatch(function(slug) {
                return "/usr/sbin/cadence task status " + slug + " " + status;
            });
            pendingAction = "";
            return true;
        }
        return false;
    }

    function handleBatchDueKey(text) {
        if (!text) return false;
        var map = { "T": "today", "W": "week", "M": "tomorrow", "N": "month" };
        var key = text.toUpperCase();
        if (!map[key]) return false;

        var d = new Date();
        switch (key) {
            case "T": break;                           // today
            case "M": d.setDate(d.getDate() + 1); break;  // tomorrow
            case "W": d.setDate(d.getDate() + 7); break;  // +1 week
            case "N": d.setMonth(d.getMonth() + 1); break; // +1 month
        }
        var yyyy = d.getFullYear();
        var mm = String(d.getMonth() + 1).padStart(2, '0');
        var dd = String(d.getDate()).padStart(2, '0');
        var dateStr = yyyy + '-' + mm + '-' + dd;

        executeBatch(function(slug) {
            return "/usr/sbin/cadence task update " + slug + " --due " + dateStr;
        });
        pendingAction = "";
        return true;
    }

    function handleBatchPriorityKey(text) {
        if (!text) return false;
        var map = { "U": "URGENT", "H": "HIGH", "M": "MEDIUM", "L": "LOW" };
        var pri = map[text.toUpperCase()];
        if (pri) {
            executeBatch(function(slug) {
                return "/usr/sbin/cadence task update " + slug + " --priority " + pri;
            });
            pendingAction = "";
            return true;
        }
        return false;
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
                var newTasks = JSON.parse(tasksFile.text());
                if (root.isLoadingMore) {
                    root.tasks = root.tasks.concat(newTasks);
                    root.isLoadingMore = false;
                } else {
                    root.tasks = newTasks;
                    root.selectedIndex = 0;
                }
                root.hasMore = newTasks.length >= root.pageSize;
                if (root.tasks.length > 0 && !root.isLoadingMore) {
                    popup.forceActiveFocus();
                }
            } catch (e) {
                console.error("Failed to parse task list:", e);
                root.tasks = [];
                root.isLoadingMore = false;
            }
        }
        onLoadFailed: function(err) {
            // ignore initial empty path
            if (path === "") return;
            console.error("Failed to read task list:", err);
            root.tasks = [];
        }
    }

    // ── batch process (multi-select operations) ──
    Process {
        id: batchProcess
        onExited: function(exitCode, exitStatus) {
            batchProcess.command = [];
            exitMultiSelect();
            loadTasks();
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
                    text: "— " + projectLabel()
                    color: "#4ecdc4"
                    font.family: "Fira Code"
                    font.pixelSize: 11
                }
            }

            // ── active filter chips ──
            Row {
                spacing: 8
                visible: statusFilter !== "" || priorityFilter !== "" || projectFilter !== ""
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

                Rectangle {
                    visible: projectFilter !== ""
                    color: "#0a1a1a"
                    border { color: "#1f3f3f"; width: 1 }
                    radius: 3
                    height: filterProjectLabel.implicitHeight + 4
                    width: filterProjectLabel.implicitWidth + 12

                    Text {
                        id: filterProjectLabel
                        anchors.centerIn: parent
                        text: "project: " + projectFilter
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

            // ── project filter bar ──
            Row {
                visible: projectFilterVisible
                spacing: 8
                width: parent.width
                height: projectFilterInput.implicitHeight + 12

                Text {
                    text: "proj"
                    color: "#c792ea"
                    font.family: "Fira Code"
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                }
                TextInput {
                    id: projectFilterInput
                    width: parent.width - 48
                    color: "#ffffff"
                    font.family: "Fira Code"
                    font.pixelSize: 14
                    activeFocusOnPress: true
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.fill: parent
                        text: "filter by project slug…"
                        color: "#333333"
                        font.family: "Fira Code"
                        font.pixelSize: 14
                        visible: !projectFilterInput.text && !projectFilterInput.activeFocus
                    }

                    onTextChanged: {
                        projectFilter = text;
                    }

                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Escape) {
                            event.accepted = true;
                            projectFilter = "";
                            projectFilterInput.text = "";
                            projectFilterVisible = false;
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

            // spacing after search / project filter
            Item { height: (searchVisible || projectFilterVisible) ? 6 : 10; width: 1 }

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
                        text: "Proj"
                        color: "#444444"
                        font.family: "Fira Code"
                        font.pixelSize: 10
                        width: 56
                    }
                    Text {
                        text: "Slug"
                        color: "#444444"
                        font.family: "Fira Code"
                        font.pixelSize: 10
                        width: 64
                    }
                    Text {
                        text: "Title"
                        color: "#444444"
                        font.family: "Fira Code"
                        font.pixelSize: 10
                        width: 220
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

            // ── batch action bar (multi-select) ──
            Rectangle {
                visible: multiSelectMode
                width: parent.width
                height: batchBarContent.implicitHeight + 10
                color: "#0a1a0f"
                border { color: "#1f3f1f"; width: 1 }
                radius: 3

                Row {
                    id: batchBarContent
                    anchors { left: parent.left; top: parent.top; margins: 8; right: parent.right }
                    spacing: 10

                    Text {
                        text: "● " + selectedCount + " selected"
                        color: "#66bb6a"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }

                    Text {
                        visible: pendingAction === "" && selectedCount > 0
                        text: "s:status  p:priority  @:due  d:delete  Esc:cancel"
                        color: "#447744"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }

                    Text {
                        visible: pendingAction === "delete"
                        text: "Delete " + selectedCount + " tasks?  d or y to confirm  any other key to cancel"
                        color: "#ff6b6b"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }

                    Text {
                        visible: pendingAction === "status"
                        text: "Set status:  T=TODO  I=IN_PROGRESS  R=IN_REVIEW  D=DONE  B=BACKLOG  Esc=cancel"
                        color: "#82aaff"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }

                    Text {
                        visible: pendingAction === "priority"
                        text: "Set priority:  U=URGENT  H=HIGH  M=MEDIUM  L=LOW  Esc=cancel"
                        color: "#ffa726"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }

                    Text {
                        visible: pendingAction === "due"
                        text: "Set due:  T=today  M=tomorrow  W=+1week  N=+1month  Esc=cancel"
                        color: "#82aaff"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                }
            }

            // ── task list ──
            ListView {
                id: taskList
                width: parent.width
                height: Math.min(400, root.height - 200)
                interactive: true
                clip: true
                keyNavigationEnabled: true
                boundsBehavior: Flickable.StopAtBounds
                flickDeceleration: 5000
                maximumFlickVelocity: 2000

                model: root.tasks
                delegate: taskRowDelegate

                // load more when scrolling near the bottom
                onContentYChanged: {
                    if (!root.hasMore || root.isLoadingMore || tasksProcess.running) return;
                    var distToBottom = taskList.contentHeight - (taskList.contentY + taskList.height);
                    if (distToBottom < 80) {
                        root.loadMoreTasks();
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    width: 6
                    contentItem: Rectangle {
                        color: "#333333"
                        radius: 3
                    }
                }

                // load-more indicator footer
                footer: Rectangle {
                    visible: root.hasMore
                    width: taskList.width
                    height: 28
                    color: "#000000"

                    Text {
                        anchors.centerIn: parent
                        text: root.isLoadingMore ? "Loading…" : (root.tasks.length > 0 ? "scroll for more…" : "")
                        color: "#333333"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                }

                // loading indicator at bottom
                footerPositioning: ListView.OverlayFooter
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
                                text: "v Space    multi-select"
                                color: "#66bb6a"
                                font.family: "Fira Code"
                                font.pixelSize: 11
                            }
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
                            Text {
                                text: "f r        project filter"
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
                        Column {
                            spacing: 3
                            Text {
                                text: "Multi-select"
                                color: "#447744"
                                font.family: "Fira Code"
                                font.pixelSize: 10
                            }
                            Text {
                                text: "s t/i/r/d/b  set status"
                                color: "#82aaff"
                                font.family: "Fira Code"
                                font.pixelSize: 11
                            }
                            Text {
                                text: "p u/h/m/l    set priority"
                                color: "#ffa726"
                                font.family: "Fira Code"
                                font.pixelSize: 11
                            }
                            Text {
                                text: "@ t/m/w/n    set due date"
                                color: "#82aaff"
                                font.family: "Fira Code"
                                font.pixelSize: 11
                            }
                            Text {
                                text: "dd or dy     delete"
                                color: "#ff6b6b"
                                font.family: "Fira Code"
                                font.pixelSize: 11
                            }
                            Text {
                                text: "Esc          exit select"
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
                    text: filteredCount() + " tasks" + (multiSelectMode ? "  ● " + selectedCount + " selected" : "")
                    color: multiSelectMode ? "#66bb6a" : "#555555"
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

                // f r project filter hint
                Row {
                    spacing: 6
                    Rectangle {
                        color: "#111111"
                        border { color: "#2a2a2a"; width: 1 }
                        radius: 2
                        height: projKeyLabel.implicitHeight + 2
                        width: projKeyLabel.implicitWidth + 8
                        Text {
                            id: projKeyLabel
                            anchors.centerIn: parent
                            text: "f r"
                            color: "#777777"
                            font.family: "Fira Code"
                            font.pixelSize: 10
                        }
                    }
                    Text {
                        text: "project"
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
            // ── multi-select mode keys ──
            if (multiSelectMode) {
                // pending action sub-keys
                if (pendingAction === "due") {
                    if (handleBatchDueKey(event.text)) {
                        event.accepted = true;
                        return;
                    }
                }
                if (pendingAction === "status") {
                    if (handleBatchStatusKey(event.text)) {
                        event.accepted = true;
                        return;
                    }
                    // non-matching key — let it fall through to nav / esc / space
                }
                if (pendingAction === "priority") {
                    if (handleBatchPriorityKey(event.text)) {
                        event.accepted = true;
                        return;
                    }
                    // non-matching key — let it fall through to nav / esc / space
                }
                if (pendingAction === "delete") {
                    if (event.key === Qt.Key_D || event.key === Qt.Key_Y) {
                        event.accepted = true;
                        executeBatch(function(slug) {
                            return "/usr/sbin/cadence task delete " + slug + " --force";
                        });
                        pendingAction = "";
                        return;
                    }
                    // any other key cancels delete pending
                    pendingAction = "";
                }

                // navigation in multi-select mode
                if (event.key === Qt.Key_J || event.key === Qt.Key_Down) {
                    event.accepted = true;
                    pendingAction = "";
                    if (root.tasks.length > 0) {
                        root.selectedIndex = Math.min(root.selectedIndex + 1, root.tasks.length - 1);
                    }
                    return;
                }
                if (event.key === Qt.Key_K || event.key === Qt.Key_Up) {
                    event.accepted = true;
                    pendingAction = "";
                    if (root.tasks.length > 0) {
                        root.selectedIndex = Math.max(root.selectedIndex - 1, 0);
                    }
                    return;
                }

                // Space / v toggles current
                if (event.key === Qt.Key_Space || event.key === Qt.Key_V) {
                    event.accepted = true;
                    pendingAction = "";
                    if (root.tasks.length > 0) {
                        toggleTaskSelection(root.tasks[root.selectedIndex].slug);
                    }
                    return;
                }

                // Escape — exit multi-select
                if (event.key === Qt.Key_Escape) {
                    event.accepted = true;
                    exitMultiSelect();
                    return;
                }

                // d — arm delete
                if (event.key === Qt.Key_D) {
                    event.accepted = true;
                    batchDelete();
                    return;
                }

                // s — arm status change
                if (event.key === Qt.Key_S) {
                    event.accepted = true;
                    pendingAction = "status";
                    pendingActionTimer.restart();
                    return;
                }

                // p — arm priority change
                if (event.key === Qt.Key_P) {
                    event.accepted = true;
                    pendingAction = "priority";
                    pendingActionTimer.restart();
                    return;
                }

                // @ — arm due date change
                if (event.key === Qt.Key_At || event.text === "@") {
                    event.accepted = true;
                    pendingAction = "due";
                    pendingActionTimer.restart();
                    return;
                }

                // ignore other keys in multi-select mode
                event.accepted = true;
                return;
            }

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
                if (event.key === Qt.Key_R) {
                    event.accepted = true;
                    filterPrefix = false;
                    projectFilterVisible = !projectFilterVisible;
                    if (projectFilterVisible) {
                        projectFilterInput.text = projectFilter;
                        projectFilterInput.forceActiveFocus();
                    } else {
                        projectFilter = "";
                        projectFilterInput.text = "";
                        selectedIndex = 0;
                        loadTasks();
                    }
                    return;
                }
                // any other key cancels prefix
                filterPrefix = false;
            }

            // v or Space — enter multi-select mode
            if (event.key === Qt.Key_V || event.key === Qt.Key_Space) {
                event.accepted = true;
                if (root.tasks.length > 0) {
                    multiSelectMode = true;
                    toggleTaskSelection(root.tasks[root.selectedIndex].slug);
                }
                return;
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

            // Escape — clear search/project filter, then close
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
                if (projectFilterVisible) {
                    projectFilter = "";
                    projectFilterInput.text = "";
                    projectFilterVisible = false;
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
                if (root.selectedTaskSlugs[modelData.slug]) return "#0a1f1a";
                if (index === root.selectedIndex) return "#0a1a1a";
                if (index % 2 === 0) return "#000000";
                return "#030303";
            }

            Row {
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 0

                // project slug / selection indicator
                Text {
                    text: {
                        if (root.selectedTaskSlugs[modelData.slug]) return "● " + (modelData._projectSlug || "");
                        if (index === root.selectedIndex) return "> " + (modelData._projectSlug || "");
                        return "  " + (modelData._projectSlug || "");
                    }
                    color: {
                        if (root.selectedTaskSlugs[modelData.slug]) return "#66bb6a";
                        if (index === root.selectedIndex) return "#c792ea";
                        return "#555555";
                    }
                    font.family: "Fira Code"
                    font.pixelSize: 10
                    width: 56
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                // slug
                Text {
                    text: modelData.slug
                    color: index === root.selectedIndex ? "#4ecdc4" : "#777777"
                    font.family: "Fira Code"
                    font.pixelSize: 11
                    width: 64
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                // title
                Text {
                    text: modelData.title
                    color: "#cccccc"
                    font.family: "Fira Code"
                    font.pixelSize: 12
                    width: 220
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
            projectFilter = "";
            projectFilterVisible = false;
            searchText = "";
            searchVisible = false;
            exitMultiSelect();
            loadTasks();
            popup.forceActiveFocus();
        }
    }
}
