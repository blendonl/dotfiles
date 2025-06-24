#!/usr/bin/env bash

selected_name=$(tmux display-message -p '#S')
selected_path=$(tmux display-message -p '#{pane_current_path}')


tmux display-popup -t "$selected_name" -d "$selected_path" -xC -yC -w80% -h80% -E "posting"


