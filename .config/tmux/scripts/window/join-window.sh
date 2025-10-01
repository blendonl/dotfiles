#!/usr/bin/env bash


source $HOME/.config/tmux/scripts/window/shared-for-windows.sh $1


if [ "${PANE_COUNT}" -gt 0 ] && [ -z "${WINDOW}" ]; then


    if [ "$INDEX" -eq "-1" ] || [ -z "$INDEX" ]; then
        exit 0;
    fi

    
    tmux break-pane -s $ACTIVE_WINDOW.$INDEX -d -n $WINDOW_NAME

    tmux set-environment "$WINDOW_NAME"_INDEX "-1"

    exit 0

fi

tmux join-pane -v -l 30% -t $ACTIVE_WINDOW.$PANE_COUNT -s $WINDOW.0


PANE_COUNT=$(tmux list-panes | egrep -o '^[^:]+' | sort -n | tail -n 1) 
tmux set-environment "$WINDOW_NAME"_INDEX "$PANE_COUNT"










