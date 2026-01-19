#!/usr/bin/env bash


source $HOME/.config/tmux/scripts/window/shared-for-windows.sh current-task 


if [ -z "${WINDOW}" ]; then
    tmux new-window -d -n  $WINDOW_NAME "mkanban task current | mkanban task show"

    WINDOW="$(tmux list-windows | grep  $WINDOW_NAME | egrep -o '^[^:]+' )"
fi


source $HOME/.config/tmux/scripts/window/join-window.sh current-task -h













