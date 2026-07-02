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
    property string blockDuration: "60"
    property bool legendVisible: false

    // ── error state ──
    property string errorText: ""
    property bool showError: false

    // ── helpers ──
    function titleText() {
        return mainInput.text.trim();
    }
    function startISO() {
        var t = startInput.text.trim();
        if (t === "") return "";
        // If already ISO, return as-is; otherwise treat as HH:MM and prepend today.
        if (t.indexOf("T") !== -1) return t;
        // Allow "now" as a special value.
        if (t.toLowerCase() === "now") {
            return new Date().toISOString();
        }
        var today = new Date();
        var y = today.getFullYear();
        var m = String(today.getMonth() + 1).padStart(2, '0');
        var d = String(today.getDate()).padStart(2, '0');
        return y + "-" + m + "-" + d + "T" + t + ":00.000Z";
    }

    function focusMainInput() {
        mainInput.forceActiveFocus();
    }

    // ── run cadence ──
    function createBlock() {
        showError = false;
        errorText = "";

        var args = ["/usr/sbin/cadence", "block", "create", "--title", titleText(), "--duration", blockDuration];
        var start = startISO();
        if (start !== "") {
            args.push("--start", start);
        }

        var cmd = args.map(function(a) {
            return "'" + a.replace(/'/g, "'\\''") + "'";
        }).join(" ");
        cmd += " 2>/tmp/cadence-block-create-error.txt";
        blockProcess.command = ["bash", "-c", cmd];
        blockProcess.running = true;
    }

    // ── process ──
    Process {
        id: blockProcess

        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                // success — clear and hide
                mainInput.text = "";
                startInput.text = "";
                blockDuration = "60";
                errorText = "";
                showError = false;
                blockProcess.command = [];
                Quickshell.execDetached(["qs", "ipc", "call", "block-create", "hide"]);
            } else {
                // failure — show error to user
                blockProcess.command = [];
                errorFile.path = "";
                errorFile.path = "/tmp/cadence-block-create-error.txt";
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

    // ── backdrop click to dismiss ──
    MouseArea {
        anchors.fill: parent
        onClicked: Quickshell.execDetached(["qs", "ipc", "call", "block-create", "hide"])
    }

    // ── centered popup ──
    Rectangle {
        anchors.centerIn: parent
        width: 500
        height: contentColumn.implicitHeight + 36
        color: "#000000"
        border { color: "#262626"; width: 1 }
        radius: 6

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
                spacing: 8
                Text {
                    text: "New Block"
                    color: "#79C0FF"
                    font.family: "Fira Code"
                    font.pixelSize: 12
                }
                Text {
                    text: "▬ time container"
                    color: "#444444"
                    font.family: "Fira Code"
                    font.pixelSize: 11
                }
            }

            // ── title input ──
            Row {
                spacing: 8
                Text {
                    text: "▸"
                    color: "#79C0FF"
                    font.family: "Fira Code"
                    font.pixelSize: 16
                }
                TextInput {
                    id: mainInput
                    width: 420
                    color: "#ffffff"
                    font.family: "Fira Code"
                    font.pixelSize: 16
                    activeFocusOnPress: true

                    Text {
                        anchors.fill: parent
                        text: "Block title (e.g. Deep Work, Focus Time)"
                        color: "#333333"
                        font.family: "Fira Code"
                        font.pixelSize: 16
                        visible: !mainInput.text && !mainInput.activeFocus
                    }

                    Keys.onPressed: function(event) {
                        // Enter — create
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            event.accepted = true;
                            if (titleText() !== "") {
                                createBlock();
                            }
                            return;
                        }
                        // Escape — cancel
                        if (event.key === Qt.Key_Escape) {
                            event.accepted = true;
                            Quickshell.execDetached(["qs", "ipc", "call", "block-create", "hide"]);
                            return;
                        }
                        // ? — toggle legend
                        if (event.key === Qt.Key_Question && text === "") {
                            event.accepted = true;
                            legendVisible = !legendVisible;
                            return;
                        }
                    }
                }
            }

            // ── start time ──
            Row {
                spacing: 16

                Column {
                    spacing: 4
                    Text {
                        text: "Start"
                        color: "#555555"
                        font.family: "Fira Code"
                        font.pixelSize: 10
                    }
                    Rectangle {
                        width: 160
                        height: 32
                        color: "#0a0a0a"
                        border { color: "#1f1f1f"; width: 1 }
                        radius: 4

                        TextInput {
                            id: startInput
                            anchors {
                                fill: parent
                                margins: 6
                            }
                            color: "#cccccc"
                            font.family: "Fira Code"
                            font.pixelSize: 13

                            Text {
                                anchors.fill: parent
                                text: "09:00 or now"
                                color: "#2a2a2a"
                                font.family: "Fira Code"
                                font.pixelSize: 13
                                visible: !startInput.text && !startInput.activeFocus
                            }

                            Keys.onPressed: function(event) {
                                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    event.accepted = true;
                                    mainInput.forceActiveFocus();
                                    return;
                                }
                                if (event.key === Qt.Key_Escape) {
                                    event.accepted = true;
                                    Quickshell.execDetached(["qs", "ipc", "call", "block-create", "hide"]);
                                    return;
                                }
                            }
                        }
                    }
                }

                Column {
                    spacing: 4
                    Text {
                        text: "Duration"
                        color: "#555555"
                        font.family: "Fira Code"
                        font.pixelSize: 10
                    }
                    Row {
                        spacing: 4
                        // 30m
                        Rectangle {
                            width: 44; height: 28
                            color: blockDuration === "30" ? "#0a141e" : "#0a0a0a"
                            border { color: blockDuration === "30" ? "#1a2a3a" : "#1f1f1f"; width: 1 }
                            radius: 4
                            Text {
                                anchors.centerIn: parent
                                text: "30m"
                                color: blockDuration === "30" ? "#79C0FF" : "#666666"
                                font.family: "Fira Code"; font.pixelSize: 11
                            }
                            MouseArea { anchors.fill: parent; onClicked: blockDuration = "30" }
                        }
                        // 1h
                        Rectangle {
                            width: 40; height: 28
                            color: blockDuration === "60" ? "#0a141e" : "#0a0a0a"
                            border { color: blockDuration === "60" ? "#1a2a3a" : "#1f1f1f"; width: 1 }
                            radius: 4
                            Text {
                                anchors.centerIn: parent
                                text: "1h"
                                color: blockDuration === "60" ? "#79C0FF" : "#666666"
                                font.family: "Fira Code"; font.pixelSize: 11
                            }
                            MouseArea { anchors.fill: parent; onClicked: blockDuration = "60" }
                        }
                        // 2h
                        Rectangle {
                            width: 40; height: 28
                            color: blockDuration === "120" ? "#0a141e" : "#0a0a0a"
                            border { color: blockDuration === "120" ? "#1a2a3a" : "#1f1f1f"; width: 1 }
                            radius: 4
                            Text {
                                anchors.centerIn: parent
                                text: "2h"
                                color: blockDuration === "120" ? "#79C0FF" : "#666666"
                                font.family: "Fira Code"; font.pixelSize: 11
                            }
                            MouseArea { anchors.fill: parent; onClicked: blockDuration = "120" }
                        }
                        // 4h
                        Rectangle {
                            width: 40; height: 28
                            color: blockDuration === "240" ? "#0a141e" : "#0a0a0a"
                            border { color: blockDuration === "240" ? "#1a2a3a" : "#1f1f1f"; width: 1 }
                            radius: 4
                            Text {
                                anchors.centerIn: parent
                                text: "4h"
                                color: blockDuration === "240" ? "#79C0FF" : "#666666"
                                font.family: "Fira Code"; font.pixelSize: 11
                            }
                            MouseArea { anchors.fill: parent; onClicked: blockDuration = "240" }
                        }
                    }
                }
            }

            // ── legend ──
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
                        text: "About Blocks"
                        color: "#555555"
                        font.family: "Fira Code"
                        font.pixelSize: 10
                    }
                    Text {
                        text: "A block is a time container that can hold multiple tasks."
                        color: "#666666"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                    Text {
                        text: "Create a block, then add tasks into it from the agenda."
                        color: "#666666"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                    Text { text: ""; height: 2 }
                    Text {
                        text: "Enter    Create block"
                        color: "#4ecdc4"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                    Text {
                        text: "Esc      Cancel"
                        color: "#555555"
                        font.family: "Fira Code"
                        font.pixelSize: 11
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
                            text: "Failed to create block"
                            color: "#ff6b6b"
                            font.family: "Fira Code"
                            font.pixelSize: 12
                        }
                        Text {
                            text: errorText
                            color: "#994444"
                            font.family: "Fira Code"
                            font.pixelSize: 11
                            width: 400
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

                // ^B tag
                Row {
                    spacing: 6
                    Text {
                        text: "⏎"
                        color: "#79C0FF"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                    Text {
                        text: "create"
                        color: "#79C0FF"
                        font.family: "Fira Code"
                        font.pixelSize: 11
                    }
                }

                // duration display
                Text {
                    text: blockDuration + "m"
                    color: "#5588aa"
                    font.family: "Fira Code"
                    font.pixelSize: 11
                }

                Item { Layout.fillWidth: true }

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
            mainInput.text = "";
            startInput.text = "";
            blockDuration = "60";
            legendVisible = false;
            showError = false;
            errorText = "";
            focusMainInput();
        }
    }
}
