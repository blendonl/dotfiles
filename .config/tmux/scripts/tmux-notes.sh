#!/usr/bin/env bash

selected_name=$(tmux display-message -p '#S')
selected_path=$(tmux display-message -p '#{pane_current_path}')


mkdir -p $selected

tmux display-popup -t "$selected_name" -d "$selected" -xC -yC -w80% -h80% -E "nvim index.md"


