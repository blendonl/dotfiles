#!/usr/bin/env bash

WINDOW_NAME="RUN"
WINDOW="$(tmux list-windows | grep  $WINDOW_NAME | egrep -o '^[^:]+' )"
ACTIVE_WINDOW="$(tmux list-windows | grep  "*" | egrep -o '^[^:]+' )"
PANE_COUNT=$(tmux list-panes | egrep -o '^[^:]+' | sort -n | tail -n 1) 
INDEX=$(tmux show-environment "$WINDOW_NAME"_INDEX 2>/dev/null | cut -d= -f2)



if [ "${PANE_COUNT}" -gt 0 ] && [ -z "${WINDOW}" ]; then


    if [ "$INDEX" -eq "-1" ] || [ -z "$INDEX" ]; then
        exit 0;
    fi

    
    tmux break-pane -s $ACTIVE_WINDOW.$INDEX -d -n $WINDOW_NAME

    tmux set-environment "$WINDOW_NAME"_INDEX "-1"

    exit 0

fi

if [ -z "${WINDOW}" ]; then
    tmux new-window -d -n $WINDOW_NAME -c "#{pane_current_path}" 


    RUN_WINDOW="$(tmux list-windows | grep  $WINDOW_NAME | egrep -o '^[^:]+' )"

    exit 0
    
fi


tmux join-pane -v -l 30% -t $ACTIVE_WINDOW.$PANE_COUNT -s $WINDOW.0


PANE_COUNT=$(tmux list-panes | egrep -o '^[^:]+' | sort -n | tail -n 1) 
tmux set-environment "$WINDOW_NAME"_INDEX "$PANE_COUNT"










