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

    // ── parsed state ──
    property string taskPriority: "MEDIUM"
    property string taskStatus: "BACKLOG"
    property string taskDue: ""
    property string taskEstimate: ""
    property string taskProject: ""
    property bool descVisible: false
    property bool legendVisible: false

    // ── project suggestions ──
    property var allProjects: []
    property var projectSuggestions: []
    property bool showProjectSuggestions: false
    property int projectSuggestionIndex: 0

    // ── helpers ──
    function titleText() {
        // strip all prefix tokens from the input
        var t = mainInput.text;
        t = t.replace(/\s*[!@~=#]\S+/g, '');
        return t.trim();
    }

    function parseInput() {
        var text = mainInput.text;

        // priority
        var priMatch = text.match(/!(\S+)/i);
        if (priMatch) {
            var p = priMatch[1].toUpperCase();
            var priMap = { URGENT: "URGENT", HIGH: "HIGH", MEDIUM: "MEDIUM", LOW: "LOW",
                           U: "URGENT", H: "HIGH", M: "MEDIUM", L: "LOW" };
            taskPriority = priMap[p] || p;
        } else {
            taskPriority = "MEDIUM";
        }

        // status
        var statMatch = text.match(/=(\S+)/i);
        if (statMatch) {
            var s = statMatch[1].toUpperCase();
            var statMap = { BACKLOG: "BACKLOG", TODO: "TODO", IN_PROGRESS: "IN_PROGRESS", DONE: "DONE",
                            B: "BACKLOG", T: "TODO", I: "IN_PROGRESS", D: "DONE" };
            taskStatus = statMap[s] || s;
        } else {
            taskStatus = "BACKLOG";
        }

        // due
        var dueMatch = text.match(/@(\S+)/);
        taskDue = dueMatch ? dueMatch[1] : "";

        // estimate
        var estMatch = text.match(/~(\S+)/);
        taskEstimate = estMatch ? estMatch[1] : "";

        // project
        var projMatch = text.match(/#(\S+)/);
        taskProject = projMatch ? projMatch[1] : "";
    }

    function focusMainInput() {
        mainInput.forceActiveFocus();
    }

    // ── project suggestion helpers ──
    function fetchProjects() {
        if (allProjects.length > 0) return;
        projectListProcess.command = ["bash", "-c",
            "/usr/sbin/cadence project list -o json > /tmp/cadence-projects.json 2>/dev/null"];
        projectListProcess.running = true;
    }

    function updateProjectSuggestions() {
        var query = taskProject.toLowerCase();
        if (query === "" || allProjects.length === 0) {
            projectSuggestions = [];
            showProjectSuggestions = false;
            return;
        }
        var matches = [];
        for (var i = 0; i < allProjects.length; i++) {
            var p = allProjects[i];
            if (p.slug.toLowerCase().indexOf(query) === 0 ||
                p.name.toLowerCase().indexOf(query) !== -1) {
                matches.push(p);
            }
        }
        projectSuggestions = matches.slice(0, 8);
        projectSuggestionIndex = 0;
        showProjectSuggestions = projectSuggestions.length > 0;
    }

    function acceptProjectSuggestion(index) {
        if (index < 0 || index >= projectSuggestions.length) return;
        var slug = projectSuggestions[index].slug;
        var text = mainInput.text;
        var hashIdx = text.lastIndexOf('#');
        if (hashIdx < 0) return;
        var afterHash = text.substring(hashIdx + 1);
        var spaceMatch = afterHash.match(/\s/);
        var endIdx = spaceMatch ? hashIdx + 1 + spaceMatch.index : text.length;
        mainInput.text = text.substring(0, hashIdx) + "#" + slug + " " + text.substring(endIdx);
        showProjectSuggestions = false;
        mainInput.forceActiveFocus();
    }

    // ── error state ──
    property string errorText: ""
    property bool showError: false

    // ── run cadence ──
    function createTask() {
        parseInput();
        showError = false;
        errorText = "";

        var args = ["/usr/sbin/cadence", "task", "create", "--title", titleText()];

        if (taskPriority !== "MEDIUM") {
            args.push("--priority", taskPriority);
        }
        if (taskStatus !== "BACKLOG") {
            args.push("--status", taskStatus);
        }
        if (taskDue !== "") {
            args.push("--due", taskDue);
        }
        if (taskEstimate !== "") {
            args.push("--estimate", taskEstimate);
        }
        if (taskProject !== "") {
            args.push("--project", taskProject);
        }
        if (descInput.text.trim() !== "") {
            args.push("--description", descInput.text.trim());
        }

        // Use bash wrapper to capture stderr to a temp file
        var cmd = args.map(function(a) {
            return "'" + a.replace(/'/g, "'\\''") + "'";
        }).join(" ");
        cmd += " 2>/tmp/cadence-task-create-error.txt";
        taskProcess.command = ["bash", "-c", cmd];
        taskProcess.running = true;
    }

    // ── process ──
    Process {
        id: taskProcess

        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                // success — clear and hide
                mainInput.text = "";
                descInput.text = "";
                descVisible = false;
                errorText = "";
                showError = false;
                taskProcess.command = [];
                Quickshell.execDetached(["qs", "ipc", "call", "task-create", "hide"]);
            } else {
                // failure — show error to user
                taskProcess.command = [];
                // toggle path to ensure FileView reloads even if same file
                errorFile.path = "";
                errorFile.path = "/tmp/cadence-task-create-error.txt";
            }
        }
    }

    // ── error file watcher ──
    FileView {
        id: errorFile
        path: ""
        onLoaded: {
            try {
                errorText = errorFile.text().trim();
                if (errorText === "") {
                    errorText = "cadence exited with non-zero status";
                }
            } catch (e) {
                errorText = "cadence failed (unknown error)";
            }
            showError = true;
            mainInput.forceActiveFocus();
        }
        onLoadFailed: {
            errorText = "cadence failed (could not read error output)";
            showError = true;
            mainInput.forceActiveFocus();
        }
    }

    // ── project list fetch ──
    Process {
        id: projectListProcess

        onExited: function(exitCode, exitStatus) {
            projectListProcess.command = [];
            if (exitCode === 0) {
                projectListFile.path = "";
                projectListFile.path = "/tmp/cadence-projects.json";
            }
        }
    }

    FileView {
        id: projectListFile
        path: ""
        onLoaded: {
            try {
                var data = JSON.parse(projectListFile.text());
                allProjects = data.items || [];
                updateProjectSuggestions();
            } catch (e) {
                allProjects = [];
            }
        }
        onLoadFailed: {
            allProjects = [];
        }
    }

    // ── backdrop click to dismiss ──
    MouseArea {
        anchors.fill: parent
        onClicked: Quickshell.execDetached(["qs", "ipc", "call", "task-create", "hide"])
    }

    // ── centered popup ──
    Rectangle {
        anchors.centerIn: parent
        width: 560
        height: contentColumn.implicitHeight + 36
        color: "#000000"
        border { color: "#262626"; width: 1 }
        radius: 6

        // swallow clicks so they don't dismiss via backdrop
        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: contentColumn
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 18
            }
            spacing: 14

            // ── header ──
            Row {
                Text {
                    text: "New Task"
                    color: "#777777"
                    font.family: "Fira Code"
                    font.pixelSize: 12
                }
            }

            // ── main input ──
            Row {
                spacing: 8
                Text {
                    text: ">"
                    color: "#4ecdc4"
                    font.family: "Fira Code"
                    font.pixelSize: 16
                }
                TextInput {
                    id: mainInput
                    width: 480
                    color: "#ffffff"
                    font.family: "Fira Code"
                    font.pixelSize: 16
                    activeFocusOnPress: true

                    Text {
                        anchors.fill: parent
                        text: "Task title"
                        color: "#333333"
                        font.family: "Fira Code"
                        font.pixelSize: 16
                        visible: !mainInput.text && !mainInput.activeFocus
                    }

                    onTextChanged: {
                        parseInput();
                        if (taskProject !== "") {
                            fetchProjects();
                            updateProjectSuggestions();
                        } else {
                            showProjectSuggestions = false;
                        }
                    }

                    Keys.onPressed: function(event) {
                        // ── suggestion navigation (when visible) ──
                        if (showProjectSuggestions) {
                            if (event.key === Qt.Key_Down) {
                                event.accepted = true;
                                projectSuggestionIndex = Math.min(projectSuggestionIndex + 1, projectSuggestions.length - 1);
                                return;
                            }
                            if (event.key === Qt.Key_Up) {
                                event.accepted = true;
                                projectSuggestionIndex = Math.max(projectSuggestionIndex - 1, 0);
                                return;
                            }
                            if (event.key === Qt.Key_Tab) {
                                event.accepted = true;
                                acceptProjectSuggestion(projectSuggestionIndex);
                                return;
                            }
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                event.accepted = true;
                                acceptProjectSuggestion(projectSuggestionIndex);
                                return;
                            }
                            if (event.key === Qt.Key_Escape) {
                                event.accepted = true;
                                showProjectSuggestions = false;
                                return;
                            }
                        }

                        // Ctrl+N — toggle description
                        if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_N) {
                            event.accepted = true;
                            descVisible = !descVisible;
                            if (descVisible) {
                                descInput.forceActiveFocus();
                            } else {
                                mainInput.forceActiveFocus();
                            }
                            return;
                        }
                        // Ctrl+D — append due prefix
                        if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_D) {
                            event.accepted = true;
                            if (text.indexOf('@') === -1) {
                                text = text.trim() + " @";
                            }
                            return;
                        }
                        // Ctrl+E — append estimate prefix
                        if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_E) {
                            event.accepted = true;
                            if (text.indexOf('~') === -1) {
                                text = text.trim() + " ~";
                            }
                            return;
                        }
                        // Ctrl+P — append project prefix
                        if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_P) {
                            event.accepted = true;
                            if (text.indexOf('#') === -1) {
                                text = text.trim() + " #";
                            }
                            return;
                        }
                        // Enter — create
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            event.accepted = true;
                            if (titleText() !== "") {
                                createTask();
                            }
                            return;
                        }
                        // Escape — cancel
                        if (event.key === Qt.Key_Escape) {
                            event.accepted = true;
                            Quickshell.execDetached(["qs", "ipc", "call", "task-create", "hide"]);
                            return;
                        }
                        // ? — toggle legend (only when input is empty)
                        if (event.key === Qt.Key_Question && text === "") {
                            event.accepted = true;
                            legendVisible = !legendVisible;
                            return;
                        }
                    }
                }
            }

            // ── project suggestion popup ──
            Rectangle {
                visible: showProjectSuggestions
                width: 480
                height: Math.min(projectSuggestions.length * 28 + 8, 232)
                color: "#0a0a0a"
                border { color: "#1f3f1f"; width: 1 }
                radius: 4

                ListView {
                    id: projectSuggestionList
                    anchors { fill: parent; margins: 4 }
                    model: projectSuggestions
                    clip: true
                    interactive: false

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 28
                        color: index === projectSuggestionIndex ? "#1a2a1a" : "transparent"
                        radius: 2

                        Row {
                            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                            spacing: 10
                            Text {
                                text: modelData.slug
                                color: "#81c784"
                                font.family: "Fira Code"
                                font.pixelSize: 12
                                width: 70
                            }
                            Text {
                                text: modelData.name
                                color: "#555555"
                                font.family: "Fira Code"
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                width: 380
                            }
                        }
                    }
                }
            }

            // ── parsed tags ──
            Row {
                spacing: 8
                visible: mainInput.text !== ""

                // priority tag
                Rectangle {
                    color: {
                        switch (taskPriority) {
                            case "URGENT": return "#1a0f0f";
                            case "HIGH":   return "#1a140a";
                            case "LOW":    return "#0a1a0f";
                            default:       return "#0a1a1a";
                        }
                    }
                    border {
                        color: {
                            switch (taskPriority) {
                                case "URGENT": return "#3f1f1f";
                                case "HIGH":   return "#3f2f1a";
                                case "LOW":    return "#1f3f1f";
                                default:       return "#1f3f3f";
                            }
                        }
                        width: 1
                    }
                    radius: 3
                    height: priorityLabel.implicitHeight + 4
                    width: priorityLabel.implicitWidth + 16

                    Text {
                        id: priorityLabel
                        anchors.centerIn: parent
                        text: taskPriority
                        color: {
                            switch (taskPriority) {
                                case "URGENT": return "#ff6b6b";
                                case "HIGH":   return "#ffa726";
                                case "LOW":    return "#66bb6a";
                                default:       return "#4ecdc4";
                            }
                        }
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                }

                // status tag
                Rectangle {
                    visible: taskStatus !== "BACKLOG"
                    color: "#0a0a0a"
                    border { color: "#2a2a2a"; width: 1 }
                    radius: 3
                    height: statusLabel.implicitHeight + 4
                    width: statusLabel.implicitWidth + 16

                    Text {
                        id: statusLabel
                        anchors.centerIn: parent
                        text: taskStatus
                        color: "#aaaaaa"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                }

                // due tag
                Rectangle {
                    visible: taskDue !== ""
                    color: "#0a0a1a"
                    border { color: "#1f1f3f"; width: 1 }
                    radius: 3
                    height: dueLabel.implicitHeight + 4
                    width: dueLabel.implicitWidth + 16

                    Text {
                        id: dueLabel
                        anchors.centerIn: parent
                        text: "@" + taskDue
                        color: "#82aaff"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                }

                // estimate tag
                Rectangle {
                    visible: taskEstimate !== ""
                    color: "#0f0a1a"
                    border { color: "#2f1f3f"; width: 1 }
                    radius: 3
                    height: estLabel.implicitHeight + 4
                    width: estLabel.implicitWidth + 16

                    Text {
                        id: estLabel
                        anchors.centerIn: parent
                        text: "~" + taskEstimate
                        color: "#c792ea"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                }

                // project tag
                Rectangle {
                    visible: taskProject !== ""
                    color: "#0f1a0f"
                    border { color: "#1f3f1f"; width: 1 }
                    radius: 3
                    height: projLabel.implicitHeight + 4
                    width: projLabel.implicitWidth + 16

                    Text {
                        id: projLabel
                        anchors.centerIn: parent
                        text: "#" + taskProject
                        color: "#81c784"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                }
            }

            // ── legend (toggled by ?) ──
            Rectangle {
                visible: legendVisible
                width: parent.width
                color: "#080808"
                border { color: "#1a1a1a"; width: 1 }
                radius: 4
                height: legendColumn.implicitHeight + 16

                Column {
                    id: legendColumn
                    anchors { left: parent.left; top: parent.top; margins: 12; right: parent.right }
                    spacing: 4

                    Text {
                        text: "Shortcuts"
                        color: "#555555"
                        font.family: "Fira Code"
                        font.pixelSize: 10
                    }
                    Text {
                        text: "!PRIORITY   Set priority (URGENT, HIGH, M, L)"
                        color: "#666666"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                    Text {
                        text: "=STATUS     Set status (TODO, DONE, I, B)"
                        color: "#666666"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                    Text {
                        text: "@DATE       Set due date (@tomorrow, @2026-07-01)"
                        color: "#666666"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                    Text {
                        text: "~MINUTES    Set estimate (~120m, ~90)"
                        color: "#666666"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                    Text {
                        text: "#PROJECT    Set project slug (#my-project)"
                        color: "#666666"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                    Text { text: ""; height: 2 }
                    Text {
                        text: "^N     Toggle description"
                        color: "#555555"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                    Text {
                        text: "^D     Append due date prefix"
                        color: "#555555"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                    Text {
                        text: "^E     Append estimate prefix"
                        color: "#555555"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                    Text {
                        text: "^P     Append project prefix"
                        color: "#555555"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                    Text {
                        text: "?      Toggle this help"
                        color: "#555555"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                    Text {
                        text: "Esc    Cancel"
                        color: "#555555"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                    Text {
                        text: "Enter  Create task"
                        color: "#4ecdc4"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                }
            }

            // ── divider ──
            Rectangle {
                width: parent.width
                height: 1
                color: "#111111"
                visible: descVisible
            }

            // ── description ──
            Column {
                visible: descVisible
                spacing: 4
                width: parent.width

                Text {
                    text: "Description"
                    color: "#555555"
                    font.family: "Fira Code"
                    font.pixelSize: 11
                }

                Rectangle {
                    width: parent.width
                    height: descInput.implicitHeight + 20
                    color: "#0a0a0a"
                    border { color: "#1f1f1f"; width: 1 }
                    radius: 4

                    TextEdit {
                        id: descInput
                        anchors {
                            fill: parent
                            margins: 10
                        }
                        color: "#cccccc"
                        font.family: "Fira Code"
                        font.pixelSize: 13
                        wrapMode: TextEdit.Wrap

                        Text {
                            anchors { left: parent.left; top: parent.top }
                            text: "Write a description..."
                            color: "#2a2a2a"
                            font.family: "Fira Code"
                            font.pixelSize: 13
                            visible: !descInput.text
                        }

                        Keys.onPressed: function(event) {
                            // Ctrl+N — toggle off
                            if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_N) {
                                event.accepted = true;
                                descVisible = false;
                                mainInput.forceActiveFocus();
                                return;
                            }
                            // Escape — cancel whole popup
                            if (event.key === Qt.Key_Escape) {
                                event.accepted = true;
                                Quickshell.execDetached(["qs", "ipc", "call", "task-create", "hide"]);
                                return;
                            }
                        }
                    }
                }
            }

            // ── error banner ──
            Rectangle {
                visible: showError
                width: parent.width
                color: "#1a0f0f"
                border { color: "#3f1f1f"; width: 1 }
                radius: 4
                height: errorColumn.implicitHeight + 20

                Row {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 12
                    }
                    spacing: 10

                    Text {
                        text: "✗"
                        color: "#ff6b6b"
                        font.family: "Fira Code"
                        font.pixelSize: 13
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        id: errorColumn
                        spacing: 2
                        Text {
                            text: "Failed to create task"
                            color: "#ff6b6b"
                            font.family: "Fira Code"
                            font.pixelSize: 12
                        }
                        Text {
                            text: errorText
                            color: "#994444"
                            font.family: "Fira Code"
                            font.pixelSize: 11
                            width: 460
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }
                    }
                }
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
                        text: "create"
                        color: "#4ecdc4"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                }

                // Ctrl+N hint
                Row {
                    spacing: 6
                    Rectangle {
                        color: "#111111"
                        border { color: "#2a2a2a"; width: 1 }
                        radius: 2
                        height: ctrlN.implicitHeight + 2
                        width: ctrlN.implicitWidth + 8
                        Text {
                            id: ctrlN
                            anchors.centerIn: parent
                            text: "^N"
                            color: "#777777"
                            font.family: "Fira Code"
                            font.pixelSize: 10
                        }
                    }
                    Text {
                        text: "description"
                        color: "#444444"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                }

                // Ctrl+D hint
                Row {
                    spacing: 6
                    Rectangle {
                        color: "#111111"
                        border { color: "#2a2a2a"; width: 1 }
                        radius: 2
                        height: ctrlD.implicitHeight + 2
                        width: ctrlD.implicitWidth + 8
                        Text {
                            id: ctrlD
                            anchors.centerIn: parent
                            text: "^D"
                            color: "#777777"
                            font.family: "Fira Code"
                            font.pixelSize: 10
                        }
                    }
                    Text {
                        text: "due"
                        color: "#444444"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                }

                // Ctrl+E hint
                Row {
                    spacing: 6
                    Rectangle {
                        color: "#111111"
                        border { color: "#2a2a2a"; width: 1 }
                        radius: 2
                        height: ctrlE.implicitHeight + 2
                        width: ctrlE.implicitWidth + 8
                        Text {
                            id: ctrlE
                            anchors.centerIn: parent
                            text: "^E"
                            color: "#777777"
                            font.family: "Fira Code"
                            font.pixelSize: 10
                        }
                    }
                    Text {
                        text: "estimate"
                        color: "#444444"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                }

                // Ctrl+P hint
                Row {
                    spacing: 6
                    Rectangle {
                        color: "#111111"
                        border { color: "#2a2a2a"; width: 1 }
                        radius: 2
                        height: ctrlP.implicitHeight + 2
                        width: ctrlP.implicitWidth + 8
                        Text {
                            id: ctrlP
                            anchors.centerIn: parent
                            text: "^P"
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

                Item { Layout.fillWidth: true }

                // Esc hint
                Row {
                    spacing: 6
                    Text {
                        text: "cancel"
                        color: "#444444"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                    Rectangle {
                        color: "#111111"
                        border { color: "#2a2a2a"; width: 1 }
                        radius: 2
                        height: escKey.implicitHeight + 2
                        width: escKey.implicitWidth + 8
                        Text {
                            id: escKey
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
    }

    // ── focus handling ──
    onVisibleChanged: {
        if (visible) {
            // fresh state each open
            mainInput.text = "";
            descInput.text = "";
            descVisible = false;
            legendVisible = false;
            showError = false;
            errorText = "";
            taskPriority = "MEDIUM";
            taskStatus = "BACKLOG";
            taskDue = "";
            taskEstimate = "";
            taskProject = "";
            showProjectSuggestions = false;
            projectSuggestions = [];
            projectSuggestionIndex = 0;
            parseInput();
            focusMainInput();
        }
    }
}
