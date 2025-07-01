#!/usr/bin/env bash

selected_name=$(tmux display-message -p '#S')
selected_path=$(tmux display-message -p '#{pane_current_path}')


if [[ "$selected_path" == *"work"* ]]; then
    selected="/mnt/data/posting/collection/work/$selected_name"
elif [[ "$selected_path" == *"personal"* ]]; then
    selected="/mnt/data/posting/collection/personal/$selected_name"
elif [[ "$selected_name" =~ ^[0-9]+$ ]]; then
    selected="/mnt/data/posting/collection/general/"
else 
    selected="/mnt/data/posting/collection/general/$selected_name"
fi

mkdir -p $selected


tmux display-popup -t "$selected_name" -d "$selected_path" -xC -yC -w80% -h80% -E "EDITOR=nvim posting --collection $selected"


