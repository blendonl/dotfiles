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
    // sections: [{label, dateKey, isToday, blocks: [...], orphanTasks: [...]}]
    // blocks: [{kind:"block", scheduledAt, title, status, durationMin, projectSlug, taskOccurrences:[...]}]
    // orphanTasks: [{kind:"orphan", ...full task dto}]
    property var sections: []
    property var flatItems: []       // [{sectionIdx, kind:"block"|"taskInBlock"|"orphan", blockData, taskData, parentBlockTitle}]
    property int selectedFlatIndex: 0
    property bool legendVisible: false
    property string searchText: ""
    property bool searchVisible: false
    property string anchorDate: ""      // YYYY-MM-DD for the week anchor
    property string prevAnchorDate: ""
    property string nextAnchorDate: ""
    property string weekLabel: ""
    property var navigation: ({})       // full navigation object from API

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

    function sectionLabel(section) {
        if (section.isToday) return "Today — " + section.dateLabel;
        return section.dateLabel;
    }
    function sectionHeaderColor(section) {
        if (section.isToday) return "#4ecdc4";
        return "#82aaff";
    }

    // ── rebuild flat list from sections ──
    function rebuildFlatItems() {
        var items = [];
        for (var si = 0; si < sections.length; si++) {
            var sec = sections[si];
            // blocks first in each section
            for (var bi = 0; bi < sec.blocks.length; bi++) {
                items.push({
                    sectionIdx: si,
                    kind: "block",
                    dataIdx: bi,
                    data: sec.blocks[bi]
                });
                // nested task occurrences inside this block
                var blk = sec.blocks[bi];
                var tasks = blk.taskOccurrences || [];
                for (var ti = 0; ti < tasks.length; ti++) {
                    items.push({
                        sectionIdx: si,
                        kind: "taskInBlock",
                        dataIdx: ti,
                        data: tasks[ti],
                        parentBlockTitle: blk.title || "(untitled)",
                        parentBlockProject: blk.project || null
                    });
                }
            }
            // orphan tasks (no block) at the end of the section
            for (var oi = 0; oi < sec.orphanTasks.length; oi++) {
                items.push({
                    sectionIdx: si,
                    kind: "orphan",
                    dataIdx: oi,
                    data: sec.orphanTasks[oi]
                });
            }
        }
        flatItems = items;
    }

    function totalItemCount() {
        var count = 0;
        for (var i = 0; i < sections.length; i++) {
            var sec = sections[i];
            count += sec.blocks.length + sec.orphanTasks.length;
            for (var bi = 0; bi < sec.blocks.length; bi++) {
                count += (sec.blocks[bi].taskOccurrences || []).length;
            }
        }
        return count;
    }

    function sectionCount() { return sections.length; }

    // ── load agenda data ──
    function loadAgenda() {
        sections = [];
        flatItems = [];

        var cmd = "/usr/sbin/cadence agenda view --mode week --output json";
        if (anchorDate) {
            cmd += " --date " + anchorDate;
        }
        if (searchText) {
            // pass search to backend?
        }
        cmd += " > /tmp/cadence-agenda-data.json";

        agendaFile.path = "";
        agendaProcess.command = ["bash", "-c", cmd];
        agendaProcess.running = true;
    }

    // ── parse week view response ──
    function parseAgendaData(jsonData) {
        try {
            var view = JSON.parse(jsonData);

            // extract navigation
            if (view.navigation) {
                anchorDate = view.navigation.anchorDate || "";
                prevAnchorDate = view.navigation.previousAnchorDate || "";
                nextAnchorDate = view.navigation.nextAnchorDate || "";
            }
            weekLabel = view.label || "";

            var dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
            var monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                              "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

            function formatDateLabel(dateKey) {
                var parts = dateKey.split("-");
                var d = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
                var dow = dayNames[d.getDay()];
                var mon = monthNames[d.getMonth()];
                var day = d.getDate();
                return dow + " " + mon + " " + day;
            }

            var days = view.days || [];
            var newSections = [];
            for (var di = 0; di < days.length; di++) {
                var day = days[di];

                // flatten timedSchedules into blocks
                var blocks = [];
                var timed = day.timedSchedules || [];
                for (var ti = 0; ti < timed.length; ti++) {
                    var sched = timed[ti].schedule;
                    blocks.push({
                        id: sched.id,
                        blockId: sched.blockId,
                        scheduledAt: sched.scheduledAt,
                        durationMinutes: sched.durationMinutes,
                        status: sched.status,
                        startedAt: sched.startedAt,
                        title: sched.title,
                        project: sched.project,
                        taskOccurrences: sched.taskOccurrences || []
                    });
                }

                var orphans = day.orphanTasks || [];

                if (blocks.length === 0 && orphans.length === 0) continue;

                newSections.push({
                    label: formatDateLabel(day.dateKey),
                    dateKey: day.dateKey,
                    dateLabel: formatDateLabel(day.dateKey),
                    isToday: day.isToday,
                    blocks: blocks,
                    orphanTasks: orphans
                });
            }

            sections = newSections;
            rebuildFlatItems();
            selectedFlatIndex = 0;
        } catch (e) {
            console.error("Failed to parse agenda data:", e);
        }
    }

    // ── navigation ──
    function moveSelectionDown() {
        if (flatItems.length > 0) {
            selectedFlatIndex = Math.min(selectedFlatIndex + 1, flatItems.length - 1);
            agendaList.positionViewAtIndex(selectedFlatIndex, ListView.Contain);
        }
    }
    function moveSelectionUp() {
        selectedFlatIndex = Math.max(selectedFlatIndex - 1, 0);
        agendaList.positionViewAtIndex(selectedFlatIndex, ListView.Contain);
    }
    function jumpToNextSection() {
        if (flatItems.length === 0) return;
        var currentSection = flatItems[selectedFlatIndex].sectionIdx;
        for (var i = selectedFlatIndex + 1; i < flatItems.length; i++) {
            if (flatItems[i].sectionIdx !== currentSection) {
                selectedFlatIndex = i;
                agendaList.positionViewAtIndex(selectedFlatIndex, ListView.Contain);
                return;
            }
        }
    }
    function jumpToPrevSection() {
        if (flatItems.length === 0) return;
        var currentSection = flatItems[selectedFlatIndex].sectionIdx;
        if (currentSection === 0) {
            selectedFlatIndex = 0;
            agendaList.positionViewAtIndex(selectedFlatIndex, ListView.Contain);
            return;
        }
        for (var i = selectedFlatIndex - 1; i >= 0; i--) {
            if (flatItems[i].sectionIdx !== currentSection) {
                var targetSection = flatItems[i].sectionIdx;
                for (var j = 0; j <= i; j++) {
                    if (flatItems[j].sectionIdx === targetSection) {
                        selectedFlatIndex = j;
                        agendaList.positionViewAtIndex(selectedFlatIndex, ListView.Contain);
                        return;
                    }
                }
            }
        }
    }
    function jumpToToday() {
        if (flatItems.length === 0) return;
        for (var i = 0; i < flatItems.length; i++) {
            var sec = sections[flatItems[i].sectionIdx];
            if (sec.isToday) {
                selectedFlatIndex = i;
                agendaList.positionViewAtIndex(selectedFlatIndex, ListView.Contain);
                return;
            }
        }
    }

    // ── week navigation ──
    function navigateWeekPrev() {
        if (prevAnchorDate) {
            anchorDate = prevAnchorDate;
            loadAgenda();
        }
    }
    function navigateWeekNext() {
        if (nextAnchorDate) {
            anchorDate = nextAnchorDate;
            loadAgenda();
        }
    }
    function navigateWeekToday() {
        anchorDate = "";
        loadAgenda();
    }

    // ── agenda data process ──
    Process {
        id: agendaProcess
        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                agendaFile.path = "/tmp/cadence-agenda-data.json";
            } else {
                sections = [];
                flatItems = [];
                weekLabel = "Error loading";
            }
        }
    }

    FileView {
        id: agendaFile
        path: ""
        onLoaded: {
            try {
                parseAgendaData(agendaFile.text());
            } catch (e) {
                console.error("Failed to read agenda data:", e);
            }
        }
        onLoadFailed: function(err) {
            if (path === "") return;
            console.error("Failed to read agenda data:", err);
        }
    }

    // ── toggle task done ──
    function toggleTaskDone(item) {
        var slug = null;
        var projectSlug = null;
        var currentStatus = null;

        if (item.kind === "taskInBlock") {
            var t = item.data.task;
            if (!t) return;
            slug = t.slug || t.id;
            currentStatus = t.status;
            if (item.parentBlockProject && item.parentBlockProject.slug) {
                projectSlug = item.parentBlockProject.slug;
            }
        } else if (item.kind === "orphan") {
            slug = item.data.slug || item.data.id;
            currentStatus = item.data.status;
        } else {
            return; // blocks not toggleable yet
        }

        if (!slug || !currentStatus) return;

        var newStatus = (currentStatus === "DONE") ? "TODO" : "DONE";
        var args = ["/usr/sbin/cadence", "task", "status", slug, newStatus, "--quiet"];
        if (projectSlug) {
            args.push("--project");
            args.push(projectSlug);
        }
        taskToggleProcess.command = args;
        taskToggleProcess.running = true;
    }

    Process {
        id: taskToggleProcess
        running: false
        onExited: function(exitCode, exitStatus) {
            taskToggleProcess.command = [];
            loadAgenda();
        }
    }

    // ── backdrop ──
    MouseArea {
        anchors.fill: parent
        onClicked: Quickshell.execDetached(["qs", "ipc", "call", "agenda", "hide"])
    }

    // ── popup ──
    Rectangle {
        id: popup
        anchors.centerIn: parent
        width: 780
        height: Math.min(popupContent.implicitHeight + 36, root.height - 60)
        color: "#000000"
        border { color: "#262626"; width: 1 }
        radius: 6
        clip: true
        focus: true

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
                    text: "Agenda"
                    color: "#777777"
                    font.family: "Fira Code"
                    font.pixelSize: 12
                }
                Text {
                    text: weekLabel
                    color: "#4ecdc4"
                    font.family: "Fira Code"
                    font.pixelSize: 11
                }
                Item { width: 1; height: 1 }
                Text {
                    text: "[ ] to change week"
                    color: "#335566"
                    font.family: "Fira Code"
                    font.pixelSize: 10
                    visible: prevAnchorDate || nextAnchorDate
                }
            }

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

                    onTextChanged: { searchText = text; }

                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Escape) {
                            event.accepted = true;
                            searchText = "";
                            searchInput.text = "";
                            searchVisible = false;
                            selectedFlatIndex = 0;
                            loadAgenda();
                            popup.forceActiveFocus();
                            return;
                        }
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            event.accepted = true;
                            selectedFlatIndex = 0;
                            loadAgenda();
                            popup.forceActiveFocus();
                            return;
                        }
                    }
                }
            }

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

                    Text { text: "";          color: "#444444"; font.family: "Fira Code"; font.pixelSize: 10; width: 34 }
                    Text { text: "✓";         color: "#444444"; font.family: "Fira Code"; font.pixelSize: 10; width: 24 }
                    Text { text: "Block/Task";color: "#444444"; font.family: "Fira Code"; font.pixelSize: 10; width: 262 }
                    Text { text: "Status";    color: "#444444"; font.family: "Fira Code"; font.pixelSize: 10; width: 100 }
                    Text { text: "Priority";  color: "#444444"; font.family: "Fira Code"; font.pixelSize: 10; width: 82 }
                    Text { text: "Due";       color: "#444444"; font.family: "Fira Code"; font.pixelSize: 10; width: 82 }
                    Text { text: "Est/Dur";   color: "#444444"; font.family: "Fira Code"; font.pixelSize: 10; width: 56 }
                    Text { text: "  ▓ = block  │ = nested task  x = toggle done"; color: "#222233"; font.family: "Fira Code"; font.pixelSize: 9 }
                }

                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: 1
                    color: "#0a0a0a"
                }
            }

            // ── list ──
            ListView {
                id: agendaList
                width: parent.width
                height: Math.min(agendaList.contentHeight, 400)
                interactive: true
                clip: true
                keyNavigationEnabled: true
                spacing: 0

                model: root.flatItems

                delegate: Component {
                    Column {
                        width: agendaList.width
                        spacing: 0
                        property var item: modelData
                        property var section: sections[modelData.sectionIdx]
                        property bool isBlock: modelData.kind === "block"
                        property bool isTaskInBlock: modelData.kind === "taskInBlock"
                        property bool isOrphan: modelData.kind === "orphan"

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
                                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                height: 1
                                color: {
                                    var sec = sections[root.flatItems[index].sectionIdx];
                                    if (sec.isToday) return "#0a1a1a";
                                    return "#0f0f1a";
                                }
                            }

                            Text {
                                id: sectionHeaderText
                                anchors { left: parent.left; top: parent.top; topMargin: 6; leftMargin: 2 }
                                text: {
                                    var sec = sections[root.flatItems[index].sectionIdx];
                                    var total = sec.blocks.length + sec.orphanTasks.length;
                                    var taskTotal = 0;
                                    for (var bi = 0; bi < sec.blocks.length; bi++) {
                                        taskTotal += (sec.blocks[bi].taskOccurrences || []).length;
                                    }
                                    var label = sectionLabel(sec);
                                    return label + "  ·  " + sec.blocks.length + " blocks" + (taskTotal > 0 ? " + " + taskTotal + " tasks" : "");
                                }
                                color: {
                                    var sec = sections[root.flatItems[index].sectionIdx];
                                    return sectionHeaderColor(sec);
                                }
                                font.family: "Fira Code"
                                font.pixelSize: 12
                            }
                        }

                        // ── BLOCK row ──
                        Rectangle {
                            visible: isBlock
                            width: parent.width
                            height: 30
                            color: {
                                if (index === root.selectedFlatIndex) return "#0a141e";
                                if (index % 2 === 0) return "#000000";
                                return "#030303";
                            }

                            Row {
                                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                                spacing: 0

                                // cursor + block icon
                                Text {
                                    text: (index === root.selectedFlatIndex ? "▸" : " ") + " ▓"
                                    color: index === root.selectedFlatIndex ? "#79C0FF" : "#5588aa"
                                    font.family: "Fira Code"
                                    font.pixelSize: 11
                                    width: 34
                                }

                                // done checkbox (display-only for blocks)
                                Text {
                                    text: modelData.data.status === "ENDED" ? "[x]" : "[ ]"
                                    color: modelData.data.status === "ENDED" ? "#66bb6a" : "#333333"
                                    font.family: "Fira Code"
                                    font.pixelSize: 12
                                    width: 24
                                }

                                // title
                                Text {
                                    text: {
                                        var t = modelData.data.title;
                                        if (!t || t === "") return "(untitled block)";
                                        return t;
                                    }
                                    color: index === root.selectedFlatIndex ? "#ffffff" : "#79C0FF"
                                    font.family: "Fira Code"
                                    font.pixelSize: 12
                                    width: 262
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }

                                // block status
                                Item {
                                    width: 100; height: parent.height
                                    Rectangle {
                                        color: blockBg()
                                        border { color: blockBorder(); width: 1 }
                                        radius: 3
                                        height: blockStatusText.implicitHeight + 4
                                        width: Math.min(blockStatusText.implicitWidth + 16, 94)
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        Text {
                                            id: blockStatusText
                                            anchors.centerIn: parent
                                            text: {
                                                switch (modelData.data.status) {
                                                    case "SCHEDULED":   return "PLANNED";
                                                    case "IN_PROGRESS": return "ACTIVE";
                                                    case "ENDED":       return "DONE";
                                                    case "UNFINISHED":  return "UNFINISHED";
                                                    default:            return modelData.data.status;
                                                }
                                            }
                                            color: {
                                                switch (modelData.data.status) {
                                                    case "IN_PROGRESS": return "#ffcb6b";
                                                    case "ENDED":       return "#66bb6a";
                                                    default:            return "#79C0FF";
                                                }
                                            }
                                            font.family: "Fira Code"
                                            font.pixelSize: 10
                                        }
                                    }
                                }

                                // task count
                                Text {
                                    text: {
                                        var tc = modelData.data.taskOccurrences ? modelData.data.taskOccurrences.length : 0;
                                        return tc > 0 ? tc + " tasks" : "empty";
                                    }
                                    color: modelData.data.taskOccurrences && modelData.data.taskOccurrences.length > 0 ? "#79C0FF" : "#334455"
                                    font.family: "Fira Code"
                                    font.pixelSize: 10
                                    width: 82
                                    leftPadding: 10
                                }

                                // scheduled time
                                Text {
                                    text: {
                                        var s = modelData.data.scheduledAt;
                                        if (!s) return "—";
                                        return s.length >= 16 ? s.substring(11, 16) : s;
                                    }
                                    color: {
                                        var sec = sections[modelData.sectionIdx];
                                        return sec.isToday ? "#79C0FF" : "#5588aa";
                                    }
                                    font.family: "Fira Code"
                                    font.pixelSize: 11
                                    width: 82
                                    leftPadding: 10
                                }

                                // duration
                                Text {
                                    text: {
                                        var dur = modelData.data.durationMinutes;
                                        if (!dur) return "—";
                                        if (dur >= 60) {
                                            var h = Math.floor(dur / 60);
                                            var rem = dur % 60;
                                            return rem === 0 ? h + "h" : h + "h" + rem + "m";
                                        }
                                        return dur + "m";
                                    }
                                    color: modelData.data.durationMinutes ? "#79C0FF" : "#333333"
                                    font.family: "Fira Code"
                                    font.pixelSize: 11
                                    width: 56
                                    leftPadding: 2
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.selectedFlatIndex = index
                            }
                        }

                        // ── TASK-IN-BLOCK row ──
                        Rectangle {
                            visible: isTaskInBlock
                            width: parent.width
                            height: 28
                            color: {
                                if (index === root.selectedFlatIndex) return "#0a1418";
                                if (index % 2 === 0) return "#000000";
                                return "#020204";
                            }

                            Row {
                                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                                spacing: 0

                                // indent + nest icon
                                Text {
                                    text: (index === root.selectedFlatIndex ? "▸" : " ") + "  │"
                                    color: index === root.selectedFlatIndex ? "#4ecdc4" : "#333344"
                                    font.family: "Fira Code"
                                    font.pixelSize: 11
                                    width: 34
                                }

                                // done checkbox (clickable)
                                Text {
                                    text: {
                                        var t = modelData.data.task;
                                        return (t && t.status === "DONE") ? "[x]" : "[ ]";
                                    }
                                    color: {
                                        var t = modelData.data.task;
                                        if (index === root.selectedFlatIndex) {
                                            return (t && t.status === "DONE") ? "#66bb6a" : "#555555";
                                        }
                                        return (t && t.status === "DONE") ? "#66bb6a" : "#333333";
                                    }
                                    font.family: "Fira Code"
                                    font.pixelSize: 12
                                    width: 24

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.toggleTaskDone(modelData)
                                    }
                                }

                                // task title
                                Text {
                                    text: {
                                        var t = modelData.data.task;
                                        if (t && t.title) return t.title;
                                        return "(untitled)";
                                    }
                                    color: {
                                        if (index === root.selectedFlatIndex) return "#ffffff";
                                        return "#999999";
                                    }
                                    font.family: "Fira Code"
                                    font.pixelSize: 11
                                    width: 262
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }

                                // task status
                                Item {
                                    width: 100; height: parent.height
                                    Rectangle {
                                        color: {
                                            var t = modelData.data.task;
                                            return t ? statBg(t.status || "") : "#0a0a0a";
                                        }
                                        border {
                                            color: {
                                                var t = modelData.data.task;
                                                return t ? statBorder(t.status || "") : "#2a2a2a";
                                            }
                                            width: 1
                                        }
                                        radius: 3
                                        height: taskStatusText.implicitHeight + 4
                                        width: Math.min(taskStatusText.implicitWidth + 16, 94)
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        Text {
                                            id: taskStatusText
                                            anchors.centerIn: parent
                                            text: {
                                                var t = modelData.data.task;
                                                return t ? (t.status || "—") : "—";
                                            }
                                            color: {
                                                var t = modelData.data.task;
                                                return t ? statColor(t.status || "") : "#888888";
                                            }
                                            font.family: "Fira Code"
                                            font.pixelSize: 9
                                        }
                                    }
                                }

                                // task priority
                                Item {
                                    width: 82; height: parent.height
                                    Rectangle {
                                        color: {
                                            var t = modelData.data.task;
                                            return t ? priBg(t.priority || "") : "#0a0a0a";
                                        }
                                        border {
                                            color: {
                                                var t = modelData.data.task;
                                                return t ? priBorder(t.priority || "") : "#2a2a2a";
                                            }
                                            width: 1
                                        }
                                        radius: 3
                                        height: taskPrioText.implicitHeight + 4
                                        width: Math.min(taskPrioText.implicitWidth + 16, 76)
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        Text {
                                            id: taskPrioText
                                            anchors.centerIn: parent
                                            text: {
                                                var t = modelData.data.task;
                                                return t ? (t.priority || "—") : "—";
                                            }
                                            color: {
                                                var t = modelData.data.task;
                                                return t ? priColor(t.priority || "") : "#888888";
                                            }
                                            font.family: "Fira Code"
                                            font.pixelSize: 9
                                        }
                                    }
                                }

                                // due date
                                Text {
                                    text: {
                                        var t = modelData.data.task;
                                        if (!t || !t.dueAt) return "—";
                                        var d = t.dueAt.substring(0, 10);
                                        var sec = sections[modelData.sectionIdx];
                                        if (sec.isToday) return "Today";
                                        return d;
                                    }
                                    color: {
                                        var t = modelData.data.task;
                                        if (!t || !t.dueAt) return "#333333";
                                        var sec = sections[modelData.sectionIdx];
                                        if (sec.isToday) return "#ff6b6b";
                                        return "#82aaff";
                                    }
                                    font.family: "Fira Code"
                                    font.pixelSize: 10
                                    width: 82
                                    leftPadding: 10
                                }

                                // estimate
                                Text {
                                    text: {
                                        var t = modelData.data.task;
                                        return formatEst(t ? t.estimatedMinutes : 0) || "—";
                                    }
                                    color: {
                                        var t = modelData.data.task;
                                        return (t && t.estimatedMinutes) ? "#c792ea" : "#333333";
                                    }
                                    font.family: "Fira Code"
                                    font.pixelSize: 10
                                    width: 56
                                    leftPadding: 2
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.selectedFlatIndex = index
                            }
                        }

                        // ── ORPHAN task row ──
                        Rectangle {
                            visible: isOrphan
                            width: parent.width
                            height: 28
                            color: {
                                if (index === root.selectedFlatIndex) return "#0a1a1a";
                                if (index % 2 === 0) return "#000000";
                                return "#030303";
                            }

                            Row {
                                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                                spacing: 0

                                // cursor + orphan icon
                                Text {
                                    text: (index === root.selectedFlatIndex ? "▸" : " ") + " ○"
                                    color: index === root.selectedFlatIndex ? "#4ecdc4" : "#444444"
                                    font.family: "Fira Code"
                                    font.pixelSize: 11
                                    width: 34
                                }

                                // done checkbox (clickable)
                                Text {
                                    text: modelData.data.status === "DONE" ? "[x]" : "[ ]"
                                    color: {
                                        if (index === root.selectedFlatIndex) {
                                            return modelData.data.status === "DONE" ? "#66bb6a" : "#555555";
                                        }
                                        return modelData.data.status === "DONE" ? "#66bb6a" : "#333333";
                                    }
                                    font.family: "Fira Code"
                                    font.pixelSize: 12
                                    width: 24

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.toggleTaskDone(modelData)
                                    }
                                }

                                // title
                                Text {
                                    text: modelData.data.title || "(untitled)"
                                    color: index === root.selectedFlatIndex ? "#ffffff" : "#cccccc"
                                    font.family: "Fira Code"
                                    font.pixelSize: 12
                                    width: 262
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }

                                // status
                                Item {
                                    width: 100; height: parent.height
                                    Rectangle {
                                        color: statBg(modelData.data.status)
                                        border { color: statBorder(modelData.data.status); width: 1 }
                                        radius: 3
                                        height: orphanStatusText.implicitHeight + 4
                                        width: Math.min(orphanStatusText.implicitWidth + 16, 94)
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        Text {
                                            id: orphanStatusText
                                            anchors.centerIn: parent
                                            text: modelData.data.status || "—"
                                            color: statColor(modelData.data.status)
                                            font.family: "Fira Code"
                                            font.pixelSize: 10
                                        }
                                    }
                                }

                                // priority
                                Item {
                                    width: 82; height: parent.height
                                    Rectangle {
                                        color: priBg(modelData.data.priority)
                                        border { color: priBorder(modelData.data.priority); width: 1 }
                                        radius: 3
                                        height: orphanPrioText.implicitHeight + 4
                                        width: Math.min(orphanPrioText.implicitWidth + 16, 76)
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        Text {
                                            id: orphanPrioText
                                            anchors.centerIn: parent
                                            text: modelData.data.priority || "—"
                                            color: priColor(modelData.data.priority)
                                            font.family: "Fira Code"
                                            font.pixelSize: 10
                                        }
                                    }
                                }

                                // due
                                Text {
                                    text: {
                                        var d = formatDue(modelData.data.dueAt);
                                        if (!d || d === "—") return "—";
                                        var sec = sections[modelData.sectionIdx];
                                        if (sec.isToday) return "Today";
                                        return d;
                                    }
                                    color: modelData.data.dueAt ? "#82aaff" : "#333333"
                                    font.family: "Fira Code"
                                    font.pixelSize: 11
                                    width: 82
                                    leftPadding: 10
                                }

                                // estimate
                                Text {
                                    text: formatEst(modelData.data.estimatedMinutes) || "—"
                                    color: modelData.data.estimatedMinutes ? "#c792ea" : "#333333"
                                    font.family: "Fira Code"
                                    font.pixelSize: 11
                                    width: 56
                                    leftPadding: 2
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.selectedFlatIndex = index
                            }
                        }
                    }
                }
            }

            // ── empty state ──
            Text {
                visible: flatItems.length === 0
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "No blocks or tasks for this week"
                color: "#333333"
                font.family: "Fira Code"
                font.pixelSize: 13
                topPadding: 24
                bottomPadding: 24
            }

            // ── legend ──
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
                        text: "Shortcuts — blocks (▓) contain tasks (│) in your agenda"
                        color: "#555555"
                        font.family: "Fira Code"
                        font.pixelSize: 10
                    }
                    Row {
                        spacing: 20
                        Column {
                            spacing: 3
                            Text { text: "jk  ↑↓    navigate"; color: "#666666"; font.family: "Fira Code"; font.pixelSize: 11 }
                            Text { text: "x          toggle done"; color: "#66bb6a"; font.family: "Fira Code"; font.pixelSize: 11 }
                            Text { text: "Enter      open task"; color: "#4ecdc4"; font.family: "Fira Code"; font.pixelSize: 11 }
                            Text { text: "Esc        close"; color: "#555555"; font.family: "Fira Code"; font.pixelSize: 11 }
                            Text { text: "[ ]        prev/next week"; color: "#666666"; font.family: "Fira Code"; font.pixelSize: 11 }
                        }
                        Column {
                            spacing: 3
                            Text { text: "t          jump today"; color: "#666666"; font.family: "Fira Code"; font.pixelSize: 11 }
                            Text { text: "n          next section"; color: "#666666"; font.family: "Fira Code"; font.pixelSize: 11 }
                            Text { text: "p          prev section"; color: "#666666"; font.family: "Fira Code"; font.pixelSize: 11 }
                            Text { text: "?          toggle help"; color: "#555555"; font.family: "Fira Code"; font.pixelSize: 11 }
                        }
                        Column {
                            spacing: 3
                            Text { text: "^N         new task"; color: "#555555"; font.family: "Fira Code"; font.pixelSize: 11 }
                            Text { text: "^B         new block"; color: "#79C0FF"; font.family: "Fira Code"; font.pixelSize: 11 }
                            Text { text: "▓ = block   │ = nested task"; color: "#335566"; font.family: "Fira Code"; font.pixelSize: 10 }
                            Text { text: "○ = orphan task (no block)"; color: "#443333"; font.family: "Fira Code"; font.pixelSize: 10 }
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
                    text: totalItemCount() + " items across " + sectionCount() + " days"
                    color: "#555555"
                    font.family: "Fira Code"
                    font.pixelSize: 11
                }

                Item { Layout.fillWidth: true }

                Row {
                    spacing: 6
                    Text { text: "⏎"; color: "#4ecdc4"; font.family: "Fira Code"; font.pixelSize: 11 }
                    Text { text: "open"; color: "#4ecdc4"; font.family: "Fira Code"; font.pixelSize: 11 }
                }
                Row { spacing: 6
                    Rectangle {
                        color: "#0a1018"; border { color: "#1a2a3a"; width: 1 }
                        radius: 2; height: blockKeyLabel.implicitHeight + 2; width: blockKeyLabel.implicitWidth + 8
                        Text {
                            id: blockKeyLabel
                            anchors.centerIn: parent; text: "^B"; color: "#79C0FF"
                            font.family: "Fira Code"; font.pixelSize: 10
                        }
                    }
                    Text { text: "block"; color: "#5588aa"; font.family: "Fira Code"; font.pixelSize: 11 }
                }
                Row {
                    spacing: 6
                    Rectangle {
                        color: "#111111"; border { color: "#2a2a2a"; width: 1 }
                        radius: 2; height: sectionNavLabel.implicitHeight + 2; width: sectionNavLabel.implicitWidth + 8
                        Text {
                            id: sectionNavLabel
                            anchors.centerIn: parent; text: "n p"; color: "#777777"
                            font.family: "Fira Code"; font.pixelSize: 10
                        }
                    }
                    Text { text: "section"; color: "#444444"; font.family: "Fira Code"; font.pixelSize: 11 }
                }
                Row {
                    spacing: 6
                    Rectangle {
                        color: "#111111"; border { color: "#2a2a2a"; width: 1 }
                        radius: 2; height: todayLabelKey.implicitHeight + 2; width: todayLabelKey.implicitWidth + 8
                        Text {
                            id: todayLabelKey
                            anchors.centerIn: parent; text: "t"; color: "#777777"
                            font.family: "Fira Code"; font.pixelSize: 10
                        }
                    }
                    Text { text: "today"; color: "#444444"; font.family: "Fira Code"; font.pixelSize: 11 }
                }
                Row {
                    spacing: 6
                    Text { text: "close"; color: "#444444"; font.family: "Fira Code"; font.pixelSize: 11 }
                    Rectangle {
                        color: "#111111"; border { color: "#2a2a2a"; width: 1 }
                        radius: 2; height: escLabel.implicitHeight + 2; width: escLabel.implicitWidth + 8
                        Text {
                            id: escLabel
                            anchors.centerIn: parent; text: "Esc"; color: "#777777"
                            font.family: "Fira Code"; font.pixelSize: 10
                        }
                    }
                }
            }
        }

        // ── keyboard handling ──
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_J || event.key === Qt.Key_Down) {
                event.accepted = true; moveSelectionDown(); return;
            }
            if (event.key === Qt.Key_K || event.key === Qt.Key_Up) {
                event.accepted = true; moveSelectionUp(); return;
            }
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                event.accepted = true; return;
            }
            if (event.key === Qt.Key_Escape) {
                event.accepted = true;
                if (searchVisible) {
                    searchText = "";
                    searchInput.text = "";
                    searchVisible = false;
                    selectedFlatIndex = 0;
                    loadAgenda();
                    return;
                }
                Quickshell.execDetached(["qs", "ipc", "call", "agenda", "hide"]);
                return;
            }
            if (event.key === Qt.Key_Question) {
                event.accepted = true; legendVisible = !legendVisible; return;
            }
            if (event.key === Qt.Key_Slash) {
                event.accepted = true;
                searchVisible = true;
                searchInput.text = "";
                searchText = "";
                searchInput.forceActiveFocus();
                return;
            }
            if (event.key === Qt.Key_T) {
                event.accepted = true; jumpToToday(); return;
            }
            if (event.key === Qt.Key_X) {
                event.accepted = true;
                if (flatItems.length > 0) toggleTaskDone(flatItems[selectedFlatIndex]);
                return;
            }
            if (event.key === Qt.Key_N) {
                event.accepted = true; jumpToNextSection(); return;
            }
            if (event.key === Qt.Key_P) {
                event.accepted = true; jumpToPrevSection(); return;
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
            if (event.key === Qt.Key_BracketLeft) {
                event.accepted = true; navigateWeekPrev(); return;
            }
            if (event.key === Qt.Key_BracketRight) {
                event.accepted = true; navigateWeekNext(); return;
            }
        }
    }

    // ── on visible ──
    onVisibleChanged: {
        if (visible) {
            selectedFlatIndex = 0;
            legendVisible = false;
            sections = [];
            flatItems = [];
            anchorDate = "";
            loadAgenda();
            popup.forceActiveFocus();
        }
    }
}
