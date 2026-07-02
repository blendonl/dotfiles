#!/usr/bin/env bash
#
# tmux command palette — run a single shell command and see output,
# or fire-and-forget with a completion notification.
#
# Usage (called from tmux binds):
#   cmd-palette.sh run       prompt for command, run in popup, pipe to less
#   cmd-palette.sh bg         prompt for command, run in background, notify
#   cmd-palette.sh last       view last background-command output
#   cmd-palette.sh --exec-run <cmd>     (internal) run in popup
#   cmd-palette.sh --exec-bg  <cmd>     (internal) run in background

set -euo pipefail

LAST_LOG="$HOME/.cache/tmux/cmd-palette-last.log"
mkdir -p "$(dirname "$LAST_LOG")"

MODE="${1:-run}"

# ── foreground: prompt → execute → page ──────────────────────────────
run_foreground() {
    tmux display-popup -h 85% -w 85% -E "$0 --run-interactive"
}

# ── the script that runs *inside* the foreground popup ───────────────
run_interactive() {
    clear
    echo "┌─────────────────────────────────────────────────────────────┐"
    echo "│  Command Palette — Run (Ctrl-C to cancel, Ctrl-D to clear) │"
    echo "└─────────────────────────────────────────────────────────────┘"
    echo ""
    read -e -p $'\033[1;32m❯\033[0m ' cmd || { echo; exit 0; }

    if [ -z "$cmd" ]; then
        exit 0
    fi

    echo ""
    echo "──── output ────"
    echo ""
    eval "$cmd" 2>&1 | less -R --no-init --quit-if-one-screen
    exit 0
}

# ── background: prompt → spawn → notify later ────────────────────────
run_background() {
    tmux display-popup -h 25% -w 70% -E "$0 --bg-interactive"
}

bg_interactive() {
    clear
    echo "┌─────────────────────────────────────────────────────────────┐"
    echo "│  Command Palette — Background (notified when done)          │"
    echo "└─────────────────────────────────────────────────────────────┘"
    echo ""
    read -e -p $'\033[1;34m❯\033[0m ' cmd || { echo; exit 0; }

    if [ -z "$cmd" ]; then
        exit 0
    fi

    local log="$LAST_LOG"
    local donefile="/tmp/tmux-cmd-done-$$"

    # Spawn detached
    (
        eval "$cmd" >"$log" 2>&1
        local rc=$?
        echo "──────────────────────" >> "$log"
        echo "Exit code: $rc" >> "$log"

        # Notify via tmux message
        tmux display-message "Command done (exit $rc): ${cmd:0:60}"

        # Desktop notification if available
        if command -v notify-send &>/dev/null; then
            local summary
            summary=$(head -5 "$log" 2>/dev/null || true)
            notify-send -u normal \
                "tmux: Command Complete (exit $rc)" \
                "$cmd\n\n${summary}" \
                --hint=int:transient:1
        fi

        rm -f "$donefile"
    ) &
    disown

    echo ""
    echo "  Spawned: ${cmd:0:70}"
    echo "  Log:     $log"
    echo ""
    echo "  You'll be notified when it finishes."
    sleep 2
    exit 0
}

# ── view last background output ──────────────────────────────────────
show_last() {
    if [ -f "$LAST_LOG" ]; then
        tmux display-popup -h 85% -w 85% -E "less -R --no-init '$LAST_LOG'"
    else
        tmux display-message "No previous background output yet."
    fi
}

# ── internal exec helpers (called via command-prompt %% substitution) ─
exec_run() {
    local cmd="$1"
    tmux display-popup -h 85% -w 85% -E "eval '$cmd' 2>&1 | less -R --no-init --quit-if-one-screen"
}

exec_bg() {
    local cmd="$1"
    local log="$LAST_LOG"
    (
        eval "$cmd" >"$log" 2>&1
        local rc=$?
        echo "──────────────────────" >> "$log"
        echo "Exit code: $rc" >> "$log"
        tmux display-message "Command done (exit $rc): ${cmd:0:60}"
        if command -v notify-send &>/dev/null; then
            local summary
            summary=$(head -5 "$log" 2>/dev/null || true)
            notify-send -u normal \
                "tmux: Command Complete (exit $rc)" \
                "$cmd\n\n${summary}" \
                --hint=int:transient:1
        fi
    ) &
    disown
    tmux display-message "Running in background: ${cmd:0:60}"
}

# ── dispatch ─────────────────────────────────────────────────────────
case "$MODE" in
    run)
        run_foreground
        ;;
    bg)
        run_background
        ;;
    last)
        show_last
        ;;
    --run-interactive)
        run_interactive
        ;;
    --bg-interactive)
        bg_interactive
        ;;
    --exec-run)
        exec_run "${2:-}"
        ;;
    --exec-bg)
        exec_bg "${2:-}"
        ;;
    *)
        echo "Usage: $0 {run|bg|last|--run-interactive|--bg-interactive|--exec-run <cmd>|--exec-bg <cmd>}"
        exit 1
        ;;
esac
