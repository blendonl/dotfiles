#!/usr/bin/env bash

selected_name=$(tmux display-message -p '#S')
selected_path=$(tmux display-message -p '#{pane_current_path}')

if [[ "$selected_path" == *"work"* ]]; then
    selected="/mnt/data/notes/work/$selected_name"
elif [[ "$selected_path" == *"personal"* ]]; then
    selected="/mnt/data/notes/personal/$selected_name"
elif [[ "$selected_name" =~ ^[0-9]+$ ]]; then
    selected="/mnt/data/notes/general/"
else 
    selected="/mnt/data/notes/general/$selected_name"
fi

mkdir -p $selected


if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    tmux new-session -s "$selected_name" -c "$selected"
    exit 0
fi

if ! tmux has-session -t="$selected_name" 2>/dev/null; then
    tmux new-session -ds "$selected_name" -c "$selected"
fi


tmux display-popup -t "$selected_name" -d "$selected" -xC -yC -w80% -h80% -E "nvim index.md"


