#!/usr/bin/env bash

selected_name=$(tmux display-message -p '#S')
selected_path=$(tmux display-message -p '#{pane_current_path}')



if [[ "$selected_path" == *"work"* ]]; then
    selected="$NOTE_PATH/work${selected_path##*work}"
elif [[ "$selected_path" == *"personal"* ]]; then
    selected="$NOTE_PATH/personal${selected_path##*personal}"
elif [[ "$selected_name" =~ ^[0-9]+$ ]]; then
    selected="$NOTE_PATH/general/"
else 
    selected="$NOTE_PATH/general/$selected_name"
fi


mkdir -p $selected

tmux display-popup -t "$selected_name" -d "$selected" -xC -yC -w80% -h80% -E "nvim index.md"


