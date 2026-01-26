#!/bin/bash

MODE=$1
WHICH_KEY_FILE="$HOME/.config/tmux/modes/${MODE}-which-key.txt"

if [[ ! -f "$WHICH_KEY_FILE" ]]; then
    exit 0
fi

tmux display-popup -E -w 60% -h 70% -B -b rounded "cat '$WHICH_KEY_FILE'"
