#!/usr/bin/env bash

selected_name=$(tmux display-message -p '#S')
selected_path=$(tmux display-message -p '#{pane_current_path}')


mkdir -p $selected


if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    tmux new-session -s "$selected_name" -c "$selected_path"
    exit 0
fi

if ! tmux has-session -t="$selected_name" 2>/dev/null; then
    tmux new-session -ds "$selected_name" -c "$selected_path"
fi


tmux display-popup -t "$selected_name" -d "$selected_path" -xC -yC -w80% -h80% -E "gh dash"


