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

    // ── parsed agenda data ──
    property var sections: []           // [{label, dateKey, isToday, isOverdue, tasks: [...], blocks: [...]}]
    property var flatItems: []          // [{sectionIdx, kind: "task"|"block", dataIdx, data}]
    property int selectedFlatIndex: 0
    property bool legendVisible: false
    property string searchText: ""
    property bool searchVisible: false
    property string anchorDate: ""      // YYYY-MM-DD for the week anchor
    property string prevAnchorDate: ""
    property string nextAnchorDate: ""
    property string weekLabel: ""

    // tracks async loads; merge when both are done
    property bool tasksLoaded: false
    property bool blocksLoaded: false

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
    function sectionLabel(section) {
        if (section.isOverdue) return "Overdue";
        if (section.isToday) return "Today — " + section.dateLabel;
        if (section.isTomorrow) return "Tomorrow — " + section.dateLabel;
        if (section.dateKey === "") return "Unscheduled";
        return section.dateLabel;
    }
    function sectionHeaderColor(section) {
        if (section.isOverdue) return "#ff6b6b";
        if (section.isToday) return "#4ecdc4";
        return "#82aaff";
    }
    // block-specific colors
    function blockColor() { return "#79C0FF"; }
    function blockBg() { return "#0a1018"; }
    function blockBorder() { return "#1a2a3a"; }

    // ── rebuild flat list from sections ──
    function rebuildFlatItems() {
        flatItems = [];
        for (var si = 0; si < sections.length; si++) {
            var sec = sections[si];
            // blocks first in each section
            for (var bi = 0; bi < sec.blocks.length; bi++) {
                flatItems.push({ sectionIdx: si, kind: "block", dataIdx: bi, data: sec.blocks[bi] });
            }
            for (var ti = 0; ti < sec.tasks.length; ti++) {
                flatItems.push({ sectionIdx: si, kind: "task", dataIdx: ti, data: sec.tasks[ti] });
            }
        }
    }

    function totalItemCount() {
        var count = 0;
        for (var i = 0; i < sections.length; i++) {
            count += sections[i].tasks.length + sections[i].blocks.length;
        }
        return count;
    }

    function sectionCount() {
        return sections.length;
    }

    function currentSectionLabel() {
        if (flatItems.length === 0) return "";
        var item = flatItems[selectedFlatIndex];
        if (!item) return "";
        return sectionLabel(sections[item.sectionIdx]);
    }

    // ── load agenda data (tasks + blocks) ──
    function loadAgenda() {
        tasksLoaded = false;
        blocksLoaded = false;
        sections = [];
        flatItems = [];

        // ── load tasks ──
        var taskCmd = "/usr/sbin/cadence task list --output json";

        // pipe through jq to include only active (non-DONE) tasks
        taskCmd += " | jq '[.[] | select(.status != \"DONE\" and .status != \"FAILED\")]'";

        // optional title search filter
        if (searchText) {
            var escaped = searchText.replace(/"/g, '\\"');
            taskCmd += " | jq '[.[] | select(.title | test(\"" + escaped + "\"; \"i\"))]'";
        }

        taskCmd += " > /tmp/cadence-agenda-tasks.json";

        tasksFile.path = "";
        tasksProcess.command = ["bash", "-c", taskCmd];
        tasksProcess.running = true;

        // ── load blocks ──
        // Fetch blocks for today through +90 days.  Overdue blocks won't be
        // caught here, but a block scheduled in the past that's still active
        // is unusual — the auto-transition handles status changes.
        var today = new Date();
        var todayStr = today.toISOString().substring(0, 10);
        var farFuture = new Date(today);
        farFuture.setDate(farFuture.getDate() + 90);
        var farFutureStr = farFuture.toISOString().substring(0, 10);

        var blockCmd = "/usr/sbin/cadence block list-occurrences --from " + todayStr + " --to " + farFutureStr + " --output json";
        // Exclude ended/skipped/cancelled blocks.
        blockCmd += " | jq '[.[] | select(.status != \"ENDED\" and .status != \"SKIPPED\" and .status != \"CANCELLED\")]'";
        blockCmd += " > /tmp/cadence-agenda-blocks.json";

        blocksFile.path = "";
        blocksProcess.command = ["bash", "-c", blockCmd];
        blocksProcess.running = true;
    }

    // ── parse & group ──
    function tryMerge() {
        if (!tasksLoaded || !blocksLoaded) return;

        // The merge always happens after both are loaded.
        // parseAndGroupTasks has already set up sections from tasks;
        // we need to merge blocks into the existing sections.
        // But since parseAndGroupTasks clears sections first, we need to
        // handle this carefully.  We store the raw data and merge when both
        // arrive.
    }

    // We store raw arrays until both loads complete.
    property var rawTasks: []
    property var rawBlocks: []

    function onTasksArrived(tasks) {
        rawTasks = tasks;
        if (blocksLoaded) {
            parseAndGroupAll(rawTasks, rawBlocks);
        }
    }

    function onBlocksArrived(blocks) {
        rawBlocks = blocks;
        if (tasksLoaded) {
            parseAndGroupAll(rawTasks, rawBlocks);
        }
    }

    function parseAndGroupAll(tasks, blocks) {
        var today = new Date();
        var todayStr = today.toISOString().substring(0, 10);
        var tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);
        var tomorrowStr = tomorrow.toISOString().substring(0, 10);

        // group tasks by date buckets
        var overdueTasks = [];
        var todayTasks = [];
        var tomorrowTasks = [];
        var futureTasks = {};  // dateKey -> tasks
        var unscheduledTasks = [];

        for (var i = 0; i < tasks.length; i++) {
            var task = tasks[i];
            var due = task.dueAt ? task.dueAt.substring(0, 10) : "";

            if (!due) {
                unscheduledTasks.push(task);
            } else if (due < todayStr) {
                overdueTasks.push(task);
            } else if (due === todayStr) {
                todayTasks.push(task);
            } else if (due === tomorrowStr) {
                tomorrowTasks.push(task);
            } else {
                if (!futureTasks[due]) futureTasks[due] = [];
                futureTasks[due].push(task);
            }
        }

        // group blocks by scheduled date
        var overdueBlocks = [];
        var todayBlocks = [];
        var tomorrowBlocks = [];
        var futureBlocks = {};  // dateKey -> blocks
        var unscheduledBlocks = [];

        for (var j = 0; j < blocks.length; j++) {
            var blk = blocks[j];
            var sched = blk.scheduledAt ? blk.scheduledAt.substring(0, 10) : "";

            if (!sched) {
                unscheduledBlocks.push(blk);
            } else if (sched < todayStr) {
                overdueBlocks.push(blk);
            } else if (sched === todayStr) {
                todayBlocks.push(blk);
            } else if (sched === tomorrowStr) {
                tomorrowBlocks.push(blk);
            } else {
                if (!futureBlocks[sched]) futureBlocks[sched] = [];
                futureBlocks[sched].push(blk);
            }
        }

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

        var newSections = [];

        // Overdue
        if (overdueBlocks.length > 0 || overdueTasks.length > 0) {
            newSections.push({ label: "Overdue", dateKey: "", dateLabel: "", isOverdue: true, isToday: false, isTomorrow: false, blocks: overdueBlocks, tasks: overdueTasks });
        }
        // Today
        if (todayBlocks.length > 0 || todayTasks.length > 0) {
            newSections.push({ label: "Today", dateKey: todayStr, dateLabel: formatDateLabel(todayStr), isOverdue: false, isToday: true, isTomorrow: false, blocks: todayBlocks, tasks: todayTasks });
        }
        // Tomorrow
        if (tomorrowBlocks.length > 0 || tomorrowTasks.length > 0) {
            newSections.push({ label: "Tomorrow", dateKey: tomorrowStr, dateLabel: formatDateLabel(tomorrowStr), isOverdue: false, isToday: false, isTomorrow: true, blocks: tomorrowBlocks, tasks: tomorrowTasks });
        }

        // future dates sorted — collect all unique date keys from both
        var allFutureDates = {};
        for (var dk in futureTasks) { allFutureDates[dk] = true; }
        for (var dk2 in futureBlocks) { allFutureDates[dk2] = true; }
        var futureDates = Object.keys(allFutureDates).sort();
        for (var fi = 0; fi < futureDates.length; fi++) {
            var fdk = futureDates[fi];
            var fb = futureBlocks[fdk] || [];
            var ft = futureTasks[fdk] || [];
            newSections.push({ label: formatDateLabel(fdk), dateKey: fdk, dateLabel: formatDateLabel(fdk), isOverdue: false, isToday: false, isTomorrow: false, blocks: fb, tasks: ft });
        }

        // Unscheduled
        if (unscheduledBlocks.length > 0 || unscheduledTasks.length > 0) {
            newSections.push({ label: "Unscheduled", dateKey: "", dateLabel: "", isOverdue: false, isToday: false, isTomorrow: false, blocks: unscheduledBlocks, tasks: unscheduledTasks });
        }

        sections = newSections;
        rebuildFlatItems();
        selectedFlatIndex = 0;
    }

    // ── navigation ──
    function moveSelectionDown() {
        if (flatItems.length > 0) {
            selectedFlatIndex = Math.min(selectedFlatIndex + 1, flatItems.length - 1);
        }
    }
    function moveSelectionUp() {
        selectedFlatIndex = Math.max(selectedFlatIndex - 1, 0);
    }
    function jumpToNextSection() {
        if (flatItems.length === 0) return;
        var currentSection = flatItems[selectedFlatIndex].sectionIdx;
        for (var i = selectedFlatIndex + 1; i < flatItems.length; i++) {
            if (flatItems[i].sectionIdx !== currentSection) {
                selectedFlatIndex = i;
                return;
            }
        }
    }
    function jumpToPrevSection() {
        if (flatItems.length === 0) return;
        var currentSection = flatItems[selectedFlatIndex].sectionIdx;
        if (currentSection === 0) {
            selectedFlatIndex = 0;
            return;
        }
        for (var i = selectedFlatIndex - 1; i >= 0; i--) {
            if (flatItems[i].sectionIdx !== currentSection) {
                var targetSection = flatItems[i].sectionIdx;
                for (var j = 0; j <= i; j++) {
                    if (flatItems[j].sectionIdx === targetSection) {
                        selectedFlatIndex = j;
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
                return;
            }
        }
    }

    // ── date navigation (week view) ──
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

    // ── task process ──
    Process {
        id: tasksProcess
        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                tasksFile.path = "/tmp/cadence-agenda-tasks.json";
            } else {
                tasksLoaded = true;
                onTasksArrived([]);
            }
        }
    }

    FileView {
        id: tasksFile
        path: ""
        onLoaded: {
            try {
                var tasks = JSON.parse(tasksFile.text());
                tasksLoaded = true;
                onTasksArrived(tasks);
            } catch (e) {
                console.error("Failed to parse agenda tasks:", e);
                tasksLoaded = true;
                onTasksArrived([]);
            }
        }
        onLoadFailed: function(err) {
            if (path === "") return;
            console.error("Failed to read agenda tasks:", err);
            tasksLoaded = true;
            onTasksArrived([]);
        }
    }

    // ── block process ──
    Process {
        id: blocksProcess
        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                blocksFile.path = "/tmp/cadence-agenda-blocks.json";
            } else {
                blocksLoaded = true;
                onBlocksArrived([]);
            }
        }
    }

    FileView {
        id: blocksFile
        path: ""
        onLoaded: {
            try {
                var blocks = JSON.parse(blocksFile.text());
                blocksLoaded = true;
                onBlocksArrived(blocks);
            } catch (e) {
                console.error("Failed to parse agenda blocks:", e);
                blocksLoaded = true;
                onBlocksArrived([]);
            }
        }
        onLoadFailed: function(err) {
            if (path === "") return;
            console.error("Failed to read agenda blocks:", err);
            blocksLoaded = true;
            onBlocksArrived([]);
        }
    }

    // ── backdrop click to dismiss ──
    MouseArea {
        anchors.fill: parent
        onClicked: Quickshell.execDetached(["qs", "ipc", "call", "agenda", "hide"])
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

                    onTextChanged: {
                        searchText = text;
                    }

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

            // spacing after search/header
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
                        text: "Kind"
                        color: "#444444"
                        font.family: "Fira Code"
                        font.pixelSize: 10
                        width: 44
                    }
                    Text {
                        text: "Title"
                        color: "#444444"
                        font.family: "Fira Code"
                        font.pixelSize: 10
                        width: 276
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
                        text: "Est/Dur"
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

            // ── agenda list (sections + rows) ──
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
                    id: agendaDelegate

                    Column {
                        width: agendaList.width
                        spacing: 0
                        property var item: modelData
                        property var section: sections[modelData.sectionIdx]
                        property int flatIdx: index
                        property bool isBlock: modelData.kind === "block"

                        // section header — only shown for first item in each section
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
                                    if (sec.isOverdue) return "#1a0f0f";
                                    if (sec.isToday) return "#0a1a1a";
                                    return "#0f0f1a";
                                }
                            }

                            Text {
                                id: sectionHeaderText
                                anchors { left: parent.left; top: parent.top; topMargin: 6; leftMargin: 2 }
                                text: {
                                    var sec = sections[root.flatItems[index].sectionIdx];
                                    var total = sec.tasks.length + sec.blocks.length;
                                    return sectionLabel(sec) + "  (" + total + ")";
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

                                // kind badge
                                Text {
                                    text: (index === root.selectedFlatIndex ? "▸" : " ") + " ▓"
                                    color: index === root.selectedFlatIndex ? "#79C0FF" : "#5588aa"
                                    font.family: "Fira Code"
                                    font.pixelSize: 11
                                    width: 44
                                }

                                // title
                                Text {
                                    text: {
                                        var t = modelData.data.title;
                                        if (!t || t === "") return "(untitled block)";
                                        return t;
                                    }
                                    color: "#79C0FF"
                                    font.family: "Fira Code"
                                    font.pixelSize: 12
                                    width: 276
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }

                                // block status tag
                                Item {
                                    width: 100
                                    height: parent.height

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

                                // task count inside block
                                Item {
                                    width: 82
                                    height: parent.height

                                    Rectangle {
                                        color: blockBg()
                                        border { color: blockBorder(); width: 1 }
                                        radius: 3
                                        height: blockTaskText.implicitHeight + 4
                                        width: Math.min(blockTaskText.implicitWidth + 16, 76)
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left

                                        Text {
                                            id: blockTaskText
                                            anchors.centerIn: parent
                                            text: {
                                                var tc = modelData.data.taskOccurrences ? modelData.data.taskOccurrences.length : 0;
                                                return tc + " task" + (tc !== 1 ? "s" : "");
                                            }
                                            color: "#79C0FF"
                                            font.family: "Fira Code"
                                            font.pixelSize: 10
                                        }
                                    }
                                }

                                // scheduled date/time
                                Text {
                                    text: {
                                        var s = modelData.data.scheduledAt;
                                        if (!s) return "—";
                                        // show time if today, otherwise date
                                        var sec = sections[modelData.sectionIdx];
                                        if (sec.isToday) {
                                            return s.length >= 16 ? s.substring(11, 16) : s;
                                        }
                                        return s.length >= 10 ? s.substring(5, 10) : s;
                                    }
                                    color: {
                                        var sec = sections[modelData.sectionIdx];
                                        if (sec.isToday) return "#79C0FF";
                                        return "#5588aa";
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

                        // ── TASK row ──
                        Rectangle {
                            visible: !isBlock
                            width: parent.width
                            height: 30
                            color: {
                                if (index === root.selectedFlatIndex) return "#0a1a1a";
                                if (index % 2 === 0) return "#000000";
                                return "#030303";
                            }

                            property bool rowIsOverdue: sections[modelData.sectionIdx].isOverdue

                            Row {
                                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                                spacing: 0

                                // slug (with > prefix when selected)
                                Text {
                                    text: (index === root.selectedFlatIndex ? "▸ " : "  ") + modelData.data.slug
                                    color: {
                                        if (index === root.selectedFlatIndex) return "#4ecdc4";
                                        if (parent.parent.rowIsOverdue) return "#664444";
                                        return "#777777";
                                    }
                                    font.family: "Fira Code"
                                    font.pixelSize: 11
                                    width: 44
                                }

                                // title
                                Text {
                                    text: modelData.data.title
                                    color: parent.parent.rowIsOverdue ? "#996666" : "#cccccc"
                                    font.family: "Fira Code"
                                    font.pixelSize: 12
                                    width: 276
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }

                                // status tag
                                Item {
                                    width: 100
                                    height: parent.height

                                    Rectangle {
                                        color: statBg(modelData.data.status)
                                        border { color: statBorder(modelData.data.status); width: 1 }
                                        radius: 3
                                        height: statusText.implicitHeight + 4
                                        width: Math.min(statusText.implicitWidth + 16, 94)
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left

                                        Text {
                                            id: statusText
                                            anchors.centerIn: parent
                                            text: modelData.data.status
                                            color: statColor(modelData.data.status)
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
                                        color: priBg(modelData.data.priority)
                                        border { color: priBorder(modelData.data.priority); width: 1 }
                                        radius: 3
                                        height: priorityText.implicitHeight + 4
                                        width: Math.min(priorityText.implicitWidth + 16, 76)
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left

                                        Text {
                                            id: priorityText
                                            anchors.centerIn: parent
                                            text: modelData.data.priority
                                            color: priColor(modelData.data.priority)
                                            font.family: "Fira Code"
                                            font.pixelSize: 10
                                        }
                                    }
                                }

                                // due date
                                Text {
                                    text: {
                                        var d = formatDue(modelData.data.dueAt);
                                        if (!d) return "—";
                                        var sec = sections[modelData.sectionIdx];
                                        if (sec.isToday) return "Today";
                                        if (sec.isTomorrow) return "Tomorrow";
                                        if (sec.isOverdue) return d;
                                        return d;
                                    }
                                    color: {
                                        var d = modelData.data.dueAt;
                                        if (!d) return "#333333";
                                        var sec = sections[modelData.sectionIdx];
                                        if (sec.isToday) return "#ff6b6b";
                                        if (sec.isOverdue) return "#ff6b6b";
                                        return "#82aaff";
                                    }
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

                            // click to select
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
                text: "No upcoming tasks or blocks"
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
                                text: "^B         new block"
                                color: "#79C0FF"
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
                                text: "t          jump today"
                                color: "#666666"
                                font.family: "Fira Code"
                                font.pixelSize: 11
                            }
                            Text {
                                text: "n          next section"
                                color: "#666666"
                                font.family: "Fira Code"
                                font.pixelSize: 11
                            }
                            Text {
                                text: "p          prev section"
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
            }

            // ── footer ──
            RowLayout {
                width: parent.width
                spacing: 16

                // count
                Text {
                    text: totalItemCount() + " items across " + sectionCount() + " sections"
                    color: "#555555"
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
                        text: "task"
                        color: "#444444"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                }

                // ^B hint
                Row {
                    spacing: 6
                    Rectangle {
                        color: "#0a1018"
                        border { color: "#1a2a3a"; width: 1 }
                        radius: 2
                        height: blockKeyLabel.implicitHeight + 2
                        width: blockKeyLabel.implicitWidth + 8
                        Text {
                            id: blockKeyLabel
                            anchors.centerIn: parent
                            text: "^B"
                            color: "#79C0FF"
                            font.family: "Fira Code"
                            font.pixelSize: 10
                        }
                    }
                    Text {
                        text: "block"
                        color: "#5588aa"
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

                // section nav hint
                Row {
                    spacing: 6
                    Rectangle {
                        color: "#111111"
                        border { color: "#2a2a2a"; width: 1 }
                        radius: 2
                        height: sectionNavLabel.implicitHeight + 2
                        width: sectionNavLabel.implicitWidth + 8
                        Text {
                            id: sectionNavLabel
                            anchors.centerIn: parent
                            text: "n p"
                            color: "#777777"
                            font.family: "Fira Code"
                            font.pixelSize: 10
                        }
                    }
                    Text {
                        text: "section"
                        color: "#444444"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                }

                // t today hint
                Row {
                    spacing: 6
                    Rectangle {
                        color: "#111111"
                        border { color: "#2a2a2a"; width: 1 }
                        radius: 2
                        height: todayLabelKey.implicitHeight + 2
                        width: todayLabelKey.implicitWidth + 8
                        Text {
                            id: todayLabelKey
                            anchors.centerIn: parent
                            text: "t"
                            color: "#777777"
                            font.family: "Fira Code"
                            font.pixelSize: 10
                        }
                    }
                    Text {
                        text: "today"
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
            // j / Down — move selection down
            if (event.key === Qt.Key_J || event.key === Qt.Key_Down) {
                event.accepted = true;
                moveSelectionDown();
                return;
            }

            // k / Up — move selection up
            if (event.key === Qt.Key_K || event.key === Qt.Key_Up) {
                event.accepted = true;
                moveSelectionUp();
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
                    selectedFlatIndex = 0;
                    loadAgenda();
                    return;
                }
                Quickshell.execDetached(["qs", "ipc", "call", "agenda", "hide"]);
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

            // t — jump to Today section
            if (event.key === Qt.Key_T) {
                event.accepted = true;
                jumpToToday();
                return;
            }

            // n — jump to next section
            if (event.key === Qt.Key_N) {
                event.accepted = true;
                jumpToNextSection();
                return;
            }

            // p — jump to previous section
            if (event.key === Qt.Key_P) {
                event.accepted = true;
                jumpToPrevSection();
                return;
            }

            // ^N — new task
            if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_N) {
                event.accepted = true;
                Quickshell.execDetached(["qs", "ipc", "call", "task-create", "open"]);
                return;
            }

            // ^B — new block
            if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_B) {
                event.accepted = true;
                Quickshell.execDetached(["qs", "ipc", "call", "block-create", "open"]);
                return;
            }

            // [ — previous week
            if (event.key === Qt.Key_BracketLeft) {
                event.accepted = true;
                navigateWeekPrev();
                return;
            }

            // ] — next week
            if (event.key === Qt.Key_BracketRight) {
                event.accepted = true;
                navigateWeekNext();
                return;
            }
        }
    }

    // ── focus + load on show ──
    onVisibleChanged: {
        if (visible) {
            selectedFlatIndex = 0;
            legendVisible = false;
            sections = [];
            flatItems = [];
            rawTasks = [];
            rawBlocks = [];
            loadAgenda();
            popup.forceActiveFocus();
        }
    }
}
