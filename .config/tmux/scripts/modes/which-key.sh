#!/bin/bash

show_which_key() {
    local mode=$1
    local which_key_file="$HOME/.config/tmux/modes/$mode-which-key.txt"
    
    if [[ -f "$which_key_file" ]]; then
        local content=$(cat "$which_key_file")
        if [[ -n "$content" ]]; then
            tmux display-popup -E -h 30% -w 50% "echo '$content' | column -t -s ':'"
        else
            tmux display-message "No which-key data found for $mode"
        fi
    else
        tmux display-message "Which-key file not found for $mode"
    fi
}

if [[ "$1" == "--show" ]]; then
    show_which_key "$2"
fi