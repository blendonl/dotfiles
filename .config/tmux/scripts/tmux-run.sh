#!/usr/bin/env bash

WINDOW_LIST=$(tmux list-windows)
RUN_WINDOW="$(tmux list-windows | grep  run | egrep -o '^[^:]+' )"
ACTIVE_WINDOW="$(tmux list-windows | grep  "*" | egrep -o '^[^:]+' )"

LIST_PANES="$(tmux list-panes -F '#F' )"
PANE_COUNT="$(echo "${LIST_PANES}" | wc -l | bc)"




if [ "${PANE_COUNT}" -gt 1 ] && [ -z "${RUN_WINDOW}" ]; then
    
    tmux break-pane -s $ACTIVE_WINDOW.1 -d -n run

    exit 0

fi

if [ -z "${RUN_WINDOW}" ]; then
    tmux new-window -d -n run -c "#{pane_current_path}" 

    RUN_WINDOW="$(tmux list-windows | grep  run | egrep -o '^[^:]+' )"
fi

tmux join-pane -h -l 25% -t $ACTIVE_WINDOW -s $RUN_WINDOW.0




