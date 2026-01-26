#!/usr/bin/env zsh

# Source zsh configuration to get PATH and environment
source ~/.zshrc 2>/dev/null || true

source $HOME/.config/tmux/scripts/window/shared-for-windows.sh $1 $2 $3


if [ -z "${WINDOW}" ]; then
    if [ -z "$2" ]; then
        tmux new-window -n $WINDOW_NAME
    elif [ -z "$3" ]; then
      tmux new-window -n $WINDOW_NAME "zsh -c '$2'"
    else
        tmux new-window -n $WINDOW_NAME -c $WINDOW_PATH "zsh -c '$2'"
    fi  

    WINDOW="$(tmux list-windows | grep  $WINDOW_NAME | egrep -o '^[^:]+' )"
fi

tmux select-window -t $WINDOW












