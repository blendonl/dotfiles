#!/usr/bin/env bash


source $HOME/.config/tmux/scripts/window/shared-for-windows.sh $1 $2 $3


if [ -z "${WINDOW}" ]; then
    tmux new-window -n $WINDOW_NAME -c $WINDOW_PATH "$2"
    echo $WINDOW_PATH


    WINDOW="$(tmux list-windows | grep  $WINDOW_NAME | egrep -o '^[^:]+' )"
fi

tmux select-window -t $WINDOW












