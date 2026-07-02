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
    property var flatItems: []
    property var projects: []
    property var selectedTaskIds: []
    property int focusedIndex: 0
    property bool legendVisible: false
    property string searchText: ""
    property bool searchVisible: false

    property bool datePickerVisible: false
    property string customDate: ""
    property string scheduleMode: ""
    property string blockProjectId: ""
    property string nlDateInput: ""
    property string parsedDateStr: ""
    property bool dateParseLoading: false
    property string dateParseError: ""

    property int totalProjects: 0
    property int loadedProjectCount: 0
    property bool projectsLoaded: false

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
        if (!d) return "—";
        return d.substring(0, 10);
    }
    function formatEst(m) {
        if (!m && m !== 0) return "—";
        if (m >= 60) {
            var h = Math.floor(m / 60);
            var rem = m % 60;
            if (rem === 0) return h + "h";
            return h + "h " + rem + "m";
        }
        return m + "m";
    }
    function blockColor() { return "#79C0FF"; }
    function blockBg() { return "#0a1018"; }
    function blockBorder() { return "#1a2a3a"; }

    function projColor(idx) {
        var colors = ["#4ecdc4", "#82aaff", "#66bb6a", "#c792ea", "#ffa726", "#79C0FF", "#ff6b6b", "#4ecdc4"];
        return colors[idx % colors.length];
    }

    function rebuildFlatItems() {
        var items = [];
        for (var pi = 0; pi < projects.length; pi++) {
            var proj = projects[pi];
            if (proj.tasks.length === 0) {
                items.push({ type: "empty", sectionIdx: pi, proj: proj });
            } else {
                for (var ti = 0; ti < proj.tasks.length; ti++) {
                    items.push({ type: "task", sectionIdx: pi, taskIdx: ti, task: proj.tasks[ti], proj: proj });
                }
            }
        }
        flatItems = items;
        if (flatItems.length > 0) {
            focusedIndex = Math.min(focusedIndex, flatItems.length - 1);
        } else {
            focusedIndex = 0;
        }
    }

    function isSelected(taskId) {
        return selectedTaskIds.indexOf(taskId) >= 0;
    }

    function toggleSelection(taskId) {
        var idx = selectedTaskIds.indexOf(taskId);
        if (idx >= 0) {
            selectedTaskIds = selectedTaskIds.filter(function(id) { return id !== taskId; });
        } else {
            selectedTaskIds = selectedTaskIds.concat([taskId]);
        }
    }

    function clearSelection() {
        selectedTaskIds = [];
        datePickerVisible = false;
        nlDateInput = "";
        parsedDateStr = "";
        dateParseError = "";
    }

    function selectedProjectNames() {
        var names = [];
        for (var i = 0; i < selectedTaskIds.length; i++) {
            for (var pi = 0; pi < projects.length; pi++) {
                for (var ti = 0; ti < projects[pi].tasks.length; ti++) {
                    if (projects[pi].tasks[ti].id === selectedTaskIds[i]) {
                        if (names.indexOf(projects[pi].name) < 0) {
                            names.push(projects[pi].name);
                        }
                    }
                }
            }
        }
        return names;
    }

    // ── navigation ──
    function moveDown() {
        if (flatItems.length > 0) focusedIndex = Math.min(focusedIndex + 1, flatItems.length - 1);
    }
    function moveUp() { focusedIndex = Math.max(focusedIndex - 1, 0); }
    function pageDown() {
        if (flatItems.length > 0) focusedIndex = Math.min(focusedIndex + 8, flatItems.length - 1);
    }
    function pageUp() { focusedIndex = Math.max(focusedIndex - 8, 0); }
    function jumpNextSection() {
        if (flatItems.length === 0) return;
        var cur = flatItems[focusedIndex].sectionIdx;
        for (var i = focusedIndex + 1; i < flatItems.length; i++) {
            if (flatItems[i].sectionIdx !== cur) { focusedIndex = i; return; }
        }
    }
    function jumpPrevSection() {
        if (flatItems.length === 0) return;
        var cur = flatItems[focusedIndex].sectionIdx;
        for (var i = focusedIndex - 1; i >= 0; i--) {
            if (flatItems[i].sectionIdx !== cur) {
                var target = flatItems[i].sectionIdx;
                for (var j = 0; j <= i; j++) {
                    if (flatItems[j].sectionIdx === target) { focusedIndex = j; return; }
                }
            }
        }
        focusedIndex = 0;
    }

    // ── dates ──
    function todayDateStr() {
        var d = new Date();
        return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, '0') + "-" + String(d.getDate()).padStart(2, '0');
    }
    function tomorrowDateStr() {
        var d = new Date();
        d.setDate(d.getDate() + 1);
        return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, '0') + "-" + String(d.getDate()).padStart(2, '0');
    }
    function dateStrOffset(days) {
        var d = new Date();
        d.setDate(d.getDate() + days);
        return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, '0') + "-" + String(d.getDate()).padStart(2, '0');
    }

    // ── scheduling ──
    function scheduleForDate(dateStr) {
        console.error("DEBUG scheduleForDate called, date:", dateStr, "selected:", selectedTaskIds.length);
        if (selectedTaskIds.length === 0) return;
        var cmds = [];
        for (var i = 0; i < selectedTaskIds.length; i++) {
            for (var pi = 0; pi < projects.length; pi++) {
                for (var ti = 0; ti < projects[pi].tasks.length; ti++) {
                    if (projects[pi].tasks[ti].id === selectedTaskIds[i]) {
                        var args = ["/usr/sbin/cadence", "task", "update", projects[pi].tasks[ti].slug, "--due", dateStr];
                        var q = args.map(function(a) {
                            return "'" + a.replace(/'/g, "'\\''") + "'";
                        }).join(" ");
                        cmds.push(q);
                    }
                }
            }
        }
        console.error("DEBUG scheduleForDate matched", cmds.length, "tasks");
        if (cmds.length === 0) return;
        var cmd = cmds.join("; ");
        cmd += " 2>/tmp/cadence-planner-schedule-error.txt";
        scheduleProcess.command = ["bash", "-c", cmd];
        scheduleProcess.running = true;
    }

    function scheduleBlock(proj, dateStr) {
        var title = proj.name + " — Work block";
        var start = dateStr + "T09:00:00Z";
        var args = ["/usr/sbin/cadence", "block", "create", "--title", title, "--start", start, "--duration", "60", "--project", proj.slug];
        var cmd = args.map(function(a) {
            return "'" + a.replace(/'/g, "'\\''") + "'";
        }).join(" ");
        cmd += " 2>/tmp/cadence-planner-schedule-error.txt";
        scheduleProcess.command = ["bash", "-c", cmd];
        scheduleProcess.running = true;
    }

    function focusScheduleInput() {
        if (selectedTaskIds.length === 0 && flatItems.length > 0 && flatItems[focusedIndex].type === "task") {
            toggleSelection(flatItems[focusedIndex].task.id);
        }
        if (selectedTaskIds.length === 0) return;
        scheduleMode = "tasks";
        nlFocusTimer.start();
    }

    // ── data loading ──
    function loadData() {
        projectsLoaded = false;
        projects = [];
        flatItems = [];
        selectedTaskIds = [];
        focusedIndex = 0;
        datePickerVisible = false;
        plannerDataFile.path = "";
        plannerDataProcess.command = ["bash", "-c", "/usr/sbin/cadence planner list --output json > /tmp/cadence-planner-data.json"];
        plannerDataProcess.running = true;
    }

    // ── single data process + file ──
    Process {
        id: plannerDataProcess
        running: false

        onExited: function(exitCode, exitStatus) {
            plannerDataProcess.command = [];
            if (exitCode === 0) {
                plannerDataFile.path = "/tmp/cadence-planner-data.json";
            } else {
                projectsLoaded = true;
            }
        }
    }

    FileView {
        id: plannerDataFile
        path: ""
        onLoaded: {
            try {
                var raw = JSON.parse(plannerDataFile.text());
                // response is { projects: [{ project: {...}, tasks: [...] }] }
                var data = raw.projects || raw;
                var projList = [];
                for (var i = 0; i < data.length; i++) {
                    var entry = data[i];
                    var p = entry.project;
                    projList.push({
                        id: p.id,
                        name: p.name,
                        slug: p.slug,
                        color: p.color || projColor(i),
                        tasks: entry.tasks || []
                    });
                }
                projects = projList;
                rebuildFlatItems();
            } catch (e) {
                console.error("Failed to parse planner data:", e);
            }
            projectsLoaded = true;
        }
        onLoadFailed: function(err) {
            if (path === "") return;
            projectsLoaded = true;
        }
    }

    Process {
        id: scheduleProcess
        running: false

        onExited: function(exitCode, exitStatus) {
            console.error("DEBUG scheduleProcess exited, code:", exitCode);
            scheduleProcess.command = [];
            if (exitCode === 0) {
                clearSelection();
                loadData();
            } else {
                console.error("scheduleProcess failed with exit code", exitCode);
                scheduleErrorFile.path = "";
                scheduleErrorFile.path = "/tmp/cadence-planner-schedule-error.txt";
            }
        }
    }

    FileView {
        id: scheduleErrorFile
        path: ""
        onLoaded: {
            console.error("scheduleProcess stderr:", scheduleErrorFile.text());
            loadData();
        }
        onLoadFailed: function(err) {
            if (path === "") return;
            console.error("scheduleProcess stderr unreadable:", err);
            loadData();
        }
    }

    Process {
        id: parseDateProcess
        running: false

        onExited: function(exitCode, exitStatus) {
            parseDateProcess.command = [];
            if (exitCode === 0) {
                parseDateFile.path = "/tmp/cadence-parsed-date.json";
            } else {
                root.dateParseLoading = false;
                root.dateParseError = "Request failed";
            }
        }
    }

    FileView {
        id: parseDateFile
        path: ""
        onLoaded: {
            root.dateParseLoading = false;
            try {
                var raw = JSON.parse(parseDateFile.text());
                if (raw.dateStr) {
                    root.parsedDateStr = raw.dateStr;
                    // Automatically schedule once the date is parsed
                    scheduleBar.doSchedule();
                } else {
                    root.dateParseError = "No date parsed";
                }
            } catch (e) {
                root.dateParseError = "Invalid response";
            }
        }
        onLoadFailed: function(err) {
            if (path === "") return;
            root.dateParseLoading = false;
            root.dateParseError = "Could not read response";
        }
    }

    Timer {
        id: nlFocusTimer
        interval: 100
        repeat: false
        onTriggered: {
            if (datePickerVisible || selectedTaskIds.length > 0) nlInput.forceActiveFocus();
        }
    }

    // ── backdrop ──
    MouseArea {
        anchors.fill: parent
        onClicked: Quickshell.execDetached(["qs", "ipc", "call", "planner", "hide"])
    }

    // ── popup ──
    Rectangle {
        id: popup
        anchors.centerIn: parent
        width: 740
        height: Math.min(popupContent.implicitHeight + 36, root.height - 60)
        color: "#000000"
        border {
            color: "#262626"
            width: 1
        }
        radius: 6
        clip: true
        focus: true

        MouseArea {
            anchors.fill: parent
        }

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
                    text: "Planner"
                    color: "#777777"
                    font.family: "Fira Code"
                    font.pixelSize: 12
                }
                Text {
                    text: "all projects"
                    color: "#4ecdc4"
                    font.family: "Fira Code"
                    font.pixelSize: 11
                }
            }

            // ── search ──
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

                    onTextChanged: searchText = text

                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Escape) {
                            event.accepted = true;
                            searchText = "";
                            searchInput.text = "";
                            searchVisible = false;
                            focusedIndex = 0;
                            popup.forceActiveFocus();
                            return;
                        }
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            event.accepted = true;
                            popup.forceActiveFocus();
                            return;
                        }
                    }
                }
            }

            Item {
                height: searchVisible ? 6 : 10
                width: 1
            }

            // ── column headers ──
            Rectangle {
                width: parent.width
                height: colHeaderRow.implicitHeight + 8
                color: "#000000"

                Row {
                    id: colHeaderRow
                    anchors {
                        left: parent.left
                        top: parent.top
                        topMargin: 4
                    }
                    spacing: 0

                    Text { text: "";        color: "#444444"; font.family: "Fira Code"; font.pixelSize: 10; width: 24 }
                    Text { text: "";        color: "#444444"; font.family: "Fira Code"; font.pixelSize: 10; width: 28 }
                    Text { text: "Slug";    color: "#444444"; font.family: "Fira Code"; font.pixelSize: 10; width: 60 }
                    Text { text: "Title";   color: "#444444"; font.family: "Fira Code"; font.pixelSize: 10; width: 264 }
                    Text { text: "Status";  color: "#444444"; font.family: "Fira Code"; font.pixelSize: 10; width: 100 }
                    Text { text: "Priority";color: "#444444"; font.family: "Fira Code"; font.pixelSize: 10; width: 82 }
                    Text { text: "Due";     color: "#444444"; font.family: "Fira Code"; font.pixelSize: 10; width: 82 }
                    Text { text: "Est";     color: "#444444"; font.family: "Fira Code"; font.pixelSize: 10; width: 56 }
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    height: 1
                    color: "#0a0a0a"
                }
            }

            // ── list ──
            ListView {
                id: plannerList
                width: parent.width
                height: 400
                interactive: true
                clip: true
                keyNavigationEnabled: true
                spacing: 0

                model: root.flatItems

                Connections {
                    target: root
                    function onFocusedIndexChanged() {
                        plannerList.positionViewAtIndex(root.focusedIndex, ListView.Contain)
                    }
                }

                delegate: Component {
                    Column {
                        width: plannerList.width
                        spacing: 0
                        property var item: modelData
                        property var proj: modelData.proj
                        property bool isTask: modelData.type === "task"
                        property bool isEmpty: modelData.type === "empty"
                        property bool selected: isTask && root.selectedTaskIds.indexOf(modelData.task.id) >= 0

                        // ── section header ──
                        Rectangle {
                            width: parent.width
                            height: sectionHeaderText.implicitHeight + 8
                            color: "#000000"
                            visible: {
                                if (index === 0) return true;
                                return root.flatItems[index].sectionIdx !== root.flatItems[index - 1].sectionIdx;
                            }

                            Rectangle {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    bottom: parent.bottom
                                }
                                height: 1
                                color: "#0f0f1a"
                            }

                            Row {
                                anchors {
                                    left: parent.left
                                    top: parent.top
                                    topMargin: 6
                                    leftMargin: 2
                                }
                                spacing: 10

                                Rectangle {
                                    width: 4
                                    height: 18
                                    radius: 2
                                    color: proj.color || "#4ecdc4"
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    id: sectionHeaderText
                                    text: proj.name + "  " + proj.slug
                                    color: "#cccccc"
                                    font.family: "Fira Code"
                                    font.pixelSize: 12
                                }

                                Text {
                                    text: {
                                        if (proj.tasks.length === 0) return "";
                                        var todo = 0;
                                        var prog = 0;
                                        for (var i = 0; i < proj.tasks.length; i++) {
                                            if (proj.tasks[i].status === "TODO") todo++;
                                            if (proj.tasks[i].status === "IN_PROGRESS") prog++;
                                        }
                                        return todo + " todo · " + prog + " in progress";
                                    }
                                    color: "#555555"
                                    font.family: "Fira Code"
                                    font.pixelSize: 10
                                }

                                Item { width: 1; height: 1 }

                                Text {
                                    text: proj.tasks.length > 0 ? proj.tasks.length + " tasks" : "empty"
                                    color: "#555555"
                                    font.family: "Fira Code"
                                    font.pixelSize: 10
                                }
                            }
                        }

                        // ── empty project row ──
                        Rectangle {
                            visible: isEmpty
                            width: parent.width
                            height: 36
                            color: {
                                if (index === root.focusedIndex) return "#0a1414";
                                if (index % 2 === 0) return "#000000";
                                return "#030303";
                            }

                            Row {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                }
                                spacing: 0

                                Text {
                                    text: index === root.focusedIndex ? "▸" : " "
                                    color: "#4ecdc4"
                                    font.family: "Fira Code"
                                    font.pixelSize: 12
                                    width: 24
                                }
                                Item { width: 28; height: 1 }
                                Text {
                                    text: "No tasks — schedule time to work on this project"
                                    color: "#555555"
                                    font.family: "Fira Code"
                                    font.pixelSize: 11
                                }
                                Item { width: 1; height: 1 }
                                Rectangle {
                                    color: blockBg()
                                    border {
                                        color: blockBorder()
                                        width: 1
                                    }
                                    radius: 3
                                    height: blockBtnText.implicitHeight + 8
                                    width: blockBtnText.implicitWidth + 20
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        id: blockBtnText
                                        anchors.centerIn: parent
                                        text: "▓ Schedule as block"
                                        color: blockColor()
                                        font.family: "Fira Code"
                                        font.pixelSize: 10
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.scheduleMode = "block";
                                            root.blockProjectId = proj.id;
                                            root.customDate = "";
                                            root.nlDateInput = "";
                                            root.parsedDateStr = "";
                                            root.dateParseError = "";
                                            root.datePickerVisible = true;
                                            nlFocusTimer.start();
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.focusedIndex = index
                            }
                        }

                        // ── task row ──
                        Rectangle {
                            visible: isTask
                            width: parent.width
                            height: 30
                            color: {
                                var sel = selected;
                                if (index === root.focusedIndex) {
                                    return sel ? "#0a1a1a" : "#0a1414";
                                }
                                if (sel) return "#0a1418";
                                if (index % 2 === 0) return "#000000";
                                return "#030303";
                            }

                            Row {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                }
                                spacing: 0

                                // cursor
                                Text {
                                    text: index === root.focusedIndex ? "▸" : " "
                                    color: "#4ecdc4"
                                    font.family: "Fira Code"
                                    font.pixelSize: 12
                                    width: 24
                                }

                                // checkbox
                                Item {
                                    width: 28
                                    height: parent.height

                                    Rectangle {
                                        width: 14
                                        height: 14
                                        anchors.centerIn: parent
                                        color: selected ? "#0f2020" : "transparent"
                                        border {
                                            color: selected ? "#4ecdc4" : "#2a2a2a"
                                            width: 1.5
                                        }
                                        radius: 3

                                        Text {
                                            anchors.centerIn: parent
                                            text: "✓"
                                            color: selected ? "#4ecdc4" : "transparent"
                                            font.family: "Fira Code"
                                            font.pixelSize: 9
                                        }
                                    }
                                }

                                // slug
                                Text {
                                    text: modelData.task.slug
                                    width: 60
                                    color: {
                                        if (index === root.focusedIndex) return "#4ecdc4";
                                        if (selected) return "#4ecdc4";
                                        return "#777777";
                                    }
                                    font.family: "Fira Code"
                                    font.pixelSize: 11
                                }

                                // title
                                Text {
                                    text: modelData.task.title
                                    color: index === root.focusedIndex ? "#ffffff" : "#cccccc"
                                    font.family: "Fira Code"
                                    font.pixelSize: 12
                                    width: 264
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }

                                // status tag
                                Item {
                                    width: 100
                                    height: parent.height

                                    Rectangle {
                                        color: statBg(modelData.task.status)
                                        border {
                                            color: statBorder(modelData.task.status)
                                            width: 1
                                        }
                                        radius: 3
                                        height: statusText.implicitHeight + 4
                                        width: Math.min(statusText.implicitWidth + 16, 94)
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left

                                        Text {
                                            id: statusText
                                            anchors.centerIn: parent
                                            text: modelData.task.status
                                            color: statColor(modelData.task.status)
                                            font.family: "Fira Code"
                                            font.pixelSize: 10
                                        }
                                    }
                                }

                                // priority tag
                                Item {
                                    width: 82
                                    height: parent.height

                                    Rectangle {
                                        color: priBg(modelData.task.priority)
                                        border {
                                            color: priBorder(modelData.task.priority)
                                            width: 1
                                        }
                                        radius: 3
                                        height: priorityText.implicitHeight + 4
                                        width: Math.min(priorityText.implicitWidth + 16, 76)
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left

                                        Text {
                                            id: priorityText
                                            anchors.centerIn: parent
                                            text: modelData.task.priority
                                            color: priColor(modelData.task.priority)
                                            font.family: "Fira Code"
                                            font.pixelSize: 10
                                        }
                                    }
                                }

                                // due date
                                Text {
                                    text: formatDue(modelData.task.dueAt)
                                    color: modelData.task.dueAt ? "#82aaff" : "#333333"
                                    font.family: "Fira Code"
                                    font.pixelSize: 11
                                    width: 82
                                    leftPadding: 10
                                }

                                // estimate
                                Text {
                                    text: formatEst(modelData.task.estimatedMinutes)
                                    color: modelData.task.estimatedMinutes ? "#c792ea" : "#333333"
                                    font.family: "Fira Code"
                                    font.pixelSize: 11
                                    width: 56
                                    leftPadding: 2
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    root.focusedIndex = index;
                                    root.toggleSelection(modelData.task.id);
                                }
                            }
                        }
                    }
                }
            }

            // ── empty / loading states ──
            Text {
                visible: !projectsLoaded
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "Loading projects…"
                color: "#555555"
                font.family: "Fira Code"
                font.pixelSize: 13
                topPadding: 24
                bottomPadding: 24
            }
            Text {
                visible: flatItems.length === 0 && projectsLoaded
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "No projects found"
                color: "#333333"
                font.family: "Fira Code"
                font.pixelSize: 13
                topPadding: 24
                bottomPadding: 24
            }

            // ── schedule bar (tasks selected or block scheduling) ──
            Rectangle {
                id: scheduleBar
                visible: selectedTaskIds.length > 0 || datePickerVisible
                width: parent.width
                color: "#080808"
                border {
                    color: "#1a1a1a"
                    width: 1
                }
                radius: 4
                height: scheduleContent.implicitHeight + 14

                Column {
                    id: scheduleContent
                    anchors {
                        left: parent.left
                        top: parent.top
                        margins: 10
                        right: parent.right
                    }
                    spacing: 8

                    // ── row 1: summary + quick buttons (tasks only) ──
                    Row {
                        spacing: 8
                        width: parent.width
                        visible: selectedTaskIds.length > 0

                        Text {
                            text: {
                                if (selectedTaskIds.length === 0) return "";
                                var names = selectedProjectNames();
                                return selectedTaskIds.length + " task" + (selectedTaskIds.length !== 1 ? "s" : "")
                                    + " from " + names.length + " project" + (names.length !== 1 ? "s" : "");
                            }
                            color: "#777777"
                            font.family: "Fira Code"
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Rectangle {
                            width: 1
                            height: 20
                            color: "#1a1a1a"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Today
                        Rectangle {
                            id: todayBtn
                            color: todayBtnHover ? "#0a1a1a" : "#0a0a0a"
                            border { color: todayBtnHover ? "#4ecdc4" : "#2a2a2a"; width: 1 }
                            radius: 3
                            height: todayBtnLabel.implicitHeight + 8
                            width: todayBtnLabel.implicitWidth + 20
                            anchors.verticalCenter: parent.verticalCenter
                            property bool todayBtnHover: false
                            Text {
                                id: todayBtnLabel
                                anchors.centerIn: parent
                                text: "Today"
                                color: todayBtn.todayBtnHover ? "#4ecdc4" : "#cccccc"
                                font.family: "Fira Code"
                                font.pixelSize: 11
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onEntered: todayBtn.todayBtnHover = true
                                onExited: todayBtn.todayBtnHover = false
                                onClicked: root.scheduleForDate(root.todayDateStr())
                            }
                        }

                        // Tomorrow
                        Rectangle {
                            id: tomBtn
                            color: tomBtnHover ? "#0a1a1a" : "#0a0a0a"
                            border { color: tomBtnHover ? "#4ecdc4" : "#2a2a2a"; width: 1 }
                            radius: 3
                            height: tomBtnLabel.implicitHeight + 8
                            width: tomBtnLabel.implicitWidth + 20
                            anchors.verticalCenter: parent.verticalCenter
                            property bool tomBtnHover: false
                            Text {
                                id: tomBtnLabel
                                anchors.centerIn: parent
                                text: "Tomorrow"
                                color: tomBtn.tomBtnHover ? "#4ecdc4" : "#cccccc"
                                font.family: "Fira Code"
                                font.pixelSize: 11
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onEntered: tomBtn.tomBtnHover = true
                                onExited: tomBtn.tomBtnHover = false
                                onClicked: root.scheduleForDate(root.tomorrowDateStr())
                            }
                        }

                        // Clear
                        Text {
                            id: clearLink
                            text: "Clear"
                            color: clearLinkHover ? "#ff6b6b" : "#555555"
                            font.family: "Fira Code"
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                            property bool clearLinkHover: false
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onEntered: clearLink.clearLinkHover = true
                                onExited: clearLink.clearLinkHover = false
                                onClicked: root.clearSelection()
                            }
                        }
                    }

                    // ── row 2: date input row ──
                    Row {
                        spacing: 8
                        width: parent.width

                        Text {
                            text: scheduleMode === "block" ? "Schedule block:" : "Schedule for:"
                            color: "#777777"
                            font.family: "Fira Code"
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Natural language date input
                        Rectangle {
                            width: 260
                            height: 28
                            color: "#000000"
                            border {
                                color: nlInput.activeFocus ? "#4ecdc4" : "#1f1f1f"
                                width: 1
                            }
                            radius: 3
                            anchors.verticalCenter: parent.verticalCenter

                            TextInput {
                                id: nlInput
                                anchors {
                                    fill: parent
                                    margins: 4
                                }
                                color: "#ffffff"
                                font.family: "Fira Code"
                                font.pixelSize: 12
                                text: root.nlDateInput
                                activeFocusOnPress: true

                                Text {
                                    anchors.fill: parent
                                    text: "e.g. Today at 5pm, next Tuesday…"
                                    color: "#333333"
                                    font.family: "Fira Code"
                                    font.pixelSize: 12
                                    visible: !nlInput.text && !nlInput.activeFocus
                                }

                                onTextChanged: {
                                    root.nlDateInput = text;
                                    root.parsedDateStr = "";
                                    root.dateParseError = "";
                                }

                                Keys.onPressed: function(event) {
                                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        event.accepted = true;
                                        if (root.nlDateInput.trim()) {
                                            scheduleBar.requestParseDate();
                                        }
                                        return;
                                    }
                                    if (event.key === Qt.Key_Escape) {
                                        event.accepted = true;
                                        root.clearSelection();
                                        popup.forceActiveFocus();
                                        return;
                                    }
                                }
                            }
                        }

                        // Parse feedback
                        Text {
                            visible: root.dateParseLoading || root.parsedDateStr !== "" || root.dateParseError !== ""
                            text: {
                                if (root.dateParseLoading) return "…";
                                if (root.dateParseError) return "✗ " + root.dateParseError;
                                if (root.parsedDateStr) return "✓ " + root.parsedDateStr;
                                return "";
                            }
                            color: {
                                if (root.dateParseError) return "#ff6b6b";
                                if (root.parsedDateStr) return "#66bb6a";
                                return "#555555";
                            }
                            font.family: "Fira Code"
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Schedule button
                        Rectangle {
                            id: schedBtn
                            color: {
                                if (!root.parsedDateStr) return "#0a0a0a";
                                return schedBtnHover ? "#0f2020" : "#0a1a1a";
                            }
                            border {
                                color: {
                                    if (!root.parsedDateStr) return "#1a1a1a";
                                    return schedBtnHover ? "#4ecdc4" : "#1f3f3f";
                                }
                                width: 1
                            }
                            radius: 3
                            height: schedBtnLabel.implicitHeight + 8
                            width: schedBtnLabel.implicitWidth + 20
                            anchors.verticalCenter: parent.verticalCenter
                            property bool schedBtnHover: false
                            opacity: root.parsedDateStr ? 1.0 : 0.4

                            Text {
                                id: schedBtnLabel
                                anchors.centerIn: parent
                                text: "Schedule"
                                color: root.parsedDateStr ? "#4ecdc4" : "#444444"
                                font.family: "Fira Code"
                                font.pixelSize: 11
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onEntered: schedBtn.schedBtnHover = true
                                onExited: schedBtn.schedBtnHover = false
                                onClicked: {
                                    if (root.parsedDateStr) scheduleBar.doSchedule();
                                }
                            }
                        }

                        // Cancel (block mode) / Clear (task mode)
                        Text {
                            id: cancelLink
                            text: scheduleMode === "block" ? "Cancel" : "Clear"
                            color: cancelLinkHover ? "#ff6b6b" : "#555555"
                            font.family: "Fira Code"
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                            property bool cancelLinkHover: false

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onEntered: cancelLink.cancelLinkHover = true
                                onExited: cancelLink.cancelLinkHover = false
                                onClicked: root.clearSelection()
                            }
                        }
                    }
                }

                function requestParseDate() {
                    if (!root.nlDateInput.trim()) return;
                    root.dateParseLoading = true;
                    root.dateParseError = "";
                    root.parsedDateStr = "";
                    parseDateFile.path = "";
                    var escaped = root.nlDateInput.replace(/'/g, "'\\''");
                    parseDateProcess.command = [
                        "bash", "-c",
                        "/usr/sbin/cadence planner parse-date '" + escaped + "' --output json > /tmp/cadence-parsed-date.json"
                    ];
                    parseDateProcess.running = true;
                }

                function doSchedule() {
                    if (!root.parsedDateStr) return;
                    root.customDate = root.parsedDateStr;
                    if (root.scheduleMode === "block") {
                        for (var i = 0; i < root.projects.length; i++) {
                            if (root.projects[i].id === root.blockProjectId) {
                                root.scheduleBlock(root.projects[i], root.customDate);
                                break;
                            }
                        }
                    } else {
                        root.scheduleForDate(root.customDate);
                    }
                    root.datePickerVisible = false;
                }
            }

            // ── legend ──
            Rectangle {
                visible: legendVisible
                width: parent.width
                color: "#080808"
                border {
                    color: "#1a1a1a"
                    width: 1
                }
                radius: 4
                height: legendContent.implicitHeight + 16

                Column {
                    id: legendContent
                    anchors {
                        left: parent.left
                        top: parent.top
                        margins: 12
                        right: parent.right
                    }
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
                            Text { text: "jk  ↑↓    navigate"; color: "#666666"; font.family: "Fira Code"; font.pixelSize: 11 }
                            Text { text: "Space      toggle select"; color: "#4ecdc4"; font.family: "Fira Code"; font.pixelSize: 11 }
                            Text { text: "Enter      schedule"; color: "#4ecdc4"; font.family: "Fira Code"; font.pixelSize: 11 }
                            Text { text: "Esc        close"; color: "#555555"; font.family: "Fira Code"; font.pixelSize: 11 }
                        }
                        Column {
                            spacing: 3
                            Text { text: "n          next section"; color: "#666666"; font.family: "Fira Code"; font.pixelSize: 11 }
                            Text { text: "p          prev section"; color: "#666666"; font.family: "Fira Code"; font.pixelSize: 11 }
                            Text { text: "^D         page down"; color: "#666666"; font.family: "Fira Code"; font.pixelSize: 11 }
                            Text { text: "^U         page up"; color: "#666666"; font.family: "Fira Code"; font.pixelSize: 11 }
                        }
                        Column {
                            spacing: 3
                            Text { text: "/          search title"; color: "#666666"; font.family: "Fira Code"; font.pixelSize: 11 }
                            Text { text: "?          toggle help"; color: "#555555"; font.family: "Fira Code"; font.pixelSize: 11 }
                            Text { text: "^N         new task"; color: "#555555"; font.family: "Fira Code"; font.pixelSize: 11 }
                            Text { text: "^B         new block"; color: "#79C0FF"; font.family: "Fira Code"; font.pixelSize: 11 }
                        }
                    }
                }
            }

            // ── divider ──
            Rectangle {
                width: parent.width
                height: 1
                color: "#111111"
            }

            // ── footer ──
            RowLayout {
                width: parent.width
                spacing: 16

                Text {
                    text: projects.length + " projects · " + flatItems.length + " items"
                    color: "#555555"
                    font.family: "Fira Code"
                    font.pixelSize: 11
                }

                Item { Layout.fillWidth: true }

                Row {
                    spacing: 6
                    Text { text: "Space"; color: "#4ecdc4"; font.family: "Fira Code"; font.pixelSize: 11 }
                    Text { text: "select"; color: "#444444"; font.family: "Fira Code"; font.pixelSize: 11 }
                }
                Row {
                    spacing: 6
                    Text { text: "⏎"; color: "#4ecdc4"; font.family: "Fira Code"; font.pixelSize: 11 }
                    Text { text: "schedule"; color: "#444444"; font.family: "Fira Code"; font.pixelSize: 11 }
                }
                Row {
                    spacing: 6
                    Rectangle {
                        color: "#111111"
                        border { color: "#2a2a2a"; width: 1 }
                        radius: 2
                        height: newKl.implicitHeight + 2
                        width: newKl.implicitWidth + 8
                        Text {
                            id: newKl
                            anchors.centerIn: parent
                            text: "^N"
                            color: "#777777"
                            font.family: "Fira Code"
                            font.pixelSize: 10
                        }
                    }
                    Text { text: "task"; color: "#444444"; font.family: "Fira Code"; font.pixelSize: 11 }
                }
                Row {
                    spacing: 6
                    Rectangle {
                        color: "#0a1018"
                        border { color: "#1a2a3a"; width: 1 }
                        radius: 2
                        height: bkKl.implicitHeight + 2
                        width: bkKl.implicitWidth + 8
                        Text {
                            id: bkKl
                            anchors.centerIn: parent
                            text: "^B"
                            color: "#79C0FF"
                            font.family: "Fira Code"
                            font.pixelSize: 10
                        }
                    }
                    Text { text: "block"; color: "#5588aa"; font.family: "Fira Code"; font.pixelSize: 11 }
                }
                Row {
                    spacing: 6
                    Rectangle {
                        color: "#111111"
                        border { color: "#2a2a2a"; width: 1 }
                        radius: 2
                        height: slKl.implicitHeight + 2
                        width: slKl.implicitWidth + 8
                        Text {
                            id: slKl
                            anchors.centerIn: parent
                            text: "/"
                            color: "#777777"
                            font.family: "Fira Code"
                            font.pixelSize: 10
                        }
                    }
                    Text { text: "search"; color: "#444444"; font.family: "Fira Code"; font.pixelSize: 11 }
                }
                Row {
                    spacing: 6
                    Rectangle {
                        color: "#111111"
                        border { color: "#2a2a2a"; width: 1 }
                        radius: 2
                        height: npKl.implicitHeight + 2
                        width: npKl.implicitWidth + 8
                        Text {
                            id: npKl
                            anchors.centerIn: parent
                            text: "n p"
                            color: "#777777"
                            font.family: "Fira Code"
                            font.pixelSize: 10
                        }
                    }
                    Text { text: "section"; color: "#444444"; font.family: "Fira Code"; font.pixelSize: 11 }
                }
                Row {
                    spacing: 6
                    Text { text: "close"; color: "#444444"; font.family: "Fira Code"; font.pixelSize: 11 }
                    Rectangle {
                        color: "#111111"
                        border { color: "#2a2a2a"; width: 1 }
                        radius: 2
                        height: escKl.implicitHeight + 2
                        width: escKl.implicitWidth + 8
                        Text {
                            id: escKl
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
            // Enter in schedule bar mode
            if ((datePickerVisible || selectedTaskIds.length > 0) && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
                event.accepted = true;
                if (parsedDateStr) {
                    customDate = parsedDateStr;
                    if (scheduleMode === "block") {
                        for (var i = 0; i < projects.length; i++) {
                            if (projects[i].id === blockProjectId) {
                                scheduleBlock(projects[i], customDate);
                                break;
                            }
                        }
                    } else {
                        scheduleForDate(customDate);
                    }
                    datePickerVisible = false;
                } else if (nlDateInput.trim()) {
                    scheduleBar.requestParseDate();
                } else {
                    nlFocusTimer.start();
                }
                return;
            }

            if (event.key === Qt.Key_J || event.key === Qt.Key_Down) {
                event.accepted = true;
                moveDown();
                return;
            }
            if (event.key === Qt.Key_K || event.key === Qt.Key_Up) {
                event.accepted = true;
                moveUp();
                return;
            }
            if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_D) {
                event.accepted = true;
                pageDown();
                return;
            }
            if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_U) {
                event.accepted = true;
                pageUp();
                return;
            }
            if (event.key === Qt.Key_Space) {
                event.accepted = true;
                if (flatItems.length > 0 && flatItems[focusedIndex].type === "task") {
                    toggleSelection(flatItems[focusedIndex].task.id);
                } else if (flatItems.length > 0 && flatItems[focusedIndex].type === "empty") {
                    scheduleMode = "block";
                    blockProjectId = flatItems[focusedIndex].proj.id;
                    nlDateInput = "";
                    parsedDateStr = "";
                    dateParseError = "";
                    datePickerVisible = true;
                    nlFocusTimer.start();
                }
                return;
            }
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                event.accepted = true;
                if (selectedTaskIds.length > 0) {
                    focusScheduleInput();
                } else if (flatItems.length > 0 && flatItems[focusedIndex].type === "task") {
                    toggleSelection(flatItems[focusedIndex].task.id);
                    focusScheduleInput();
                } else if (flatItems.length > 0 && flatItems[focusedIndex].type === "empty") {
                    scheduleMode = "block";
                    blockProjectId = flatItems[focusedIndex].proj.id;
                    nlDateInput = "";
                    parsedDateStr = "";
                    dateParseError = "";
                    datePickerVisible = true;
                    nlFocusTimer.start();
                }
                return;
            }
            if (event.key === Qt.Key_Escape) {
                event.accepted = true;
                if (datePickerVisible) {
                    datePickerVisible = false;
                    return;
                }
                if (searchVisible) {
                    searchText = "";
                    searchInput.text = "";
                    searchVisible = false;
                    focusedIndex = 0;
                    return;
                }
                if (selectedTaskIds.length > 0) {
                    clearSelection();
                    return;
                }
                Quickshell.execDetached(["qs", "ipc", "call", "planner", "hide"]);
                return;
            }
            if (event.key === Qt.Key_Question) {
                event.accepted = true;
                legendVisible = !legendVisible;
                return;
            }
            if (event.key === Qt.Key_Slash) {
                event.accepted = true;
                searchVisible = true;
                searchInput.text = "";
                searchText = "";
                searchInput.forceActiveFocus();
                return;
            }
            if (event.key === Qt.Key_N) {
                event.accepted = true;
                jumpNextSection();
                return;
            }
            if (event.key === Qt.Key_P) {
                event.accepted = true;
                jumpPrevSection();
                return;
            }
            if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_N) {
                event.accepted = true;
                Quickshell.execDetached(["qs", "ipc", "call", "task-create", "open"]);
                return;
            }
            if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_B) {
                event.accepted = true;
                Quickshell.execDetached(["qs", "ipc", "call", "block-create", "open"]);
                return;
            }
        }
    }

    // ── on visible ──
    onVisibleChanged: {
        if (visible) {
            focusedIndex = 0;
            legendVisible = false;
            selectedTaskIds = [];
            datePickerVisible = false;
            customDate = "";
            nlDateInput = "";
            parsedDateStr = "";
            dateParseError = "";
            searchText = "";
            searchVisible = false;
            loadData();
            popup.forceActiveFocus();
        }
    }
}
