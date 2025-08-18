#!/usr/bin/env bash

WINDOW_LIST=$(tmux list-windows)
CLAUDE_WINDOW="$(tmux list-windows | grep  claude | egrep -o '^[^:]+' )"
ACTIVE_WINDOW="$(tmux list-windows | grep  "*" | egrep -o '^[^:]+' )"

LIST_PANES="$(tmux list-panes -F '#F' )"
PANE_COUNT="$(echo "${LIST_PANES}" | wc -l | bc)"

if [ "${PANE_COUNT}" = 1 ]; then
    if [ -z "${CLAUDE_WINDOW}" ]; then
        tmux new-window -d -n claude -c "#{pane_current_path}" claude 

        CLAUDE_WINDOW="$(tmux list-windows | grep  claude | egrep -o '^[^:]+' )"
    fi

    tmux join-pane -t $ACTIVE_WINDOW -s $CLAUDE_WINDOW
else
    tmux break-pane -d
fi




