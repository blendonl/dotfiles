#!/usr/bin/env bash

selected_name=$(tmux display-message -p '#S')
selected_path=$(tmux display-message -p '#{pane_current_path}')


if [[ "$selected_path" == *"work"* ]]; then
    selected="$REST_DATA/collection/work/$selected_name"
elif [[ "$selected_path" == *"personal"* ]]; then
    selected="$REST_DATA/collection/personal/$selected_name"
elif [[ "$selected_name" =~ ^[0-9]+$ ]]; then
    selected="$REST_DATA/collection/general/"
else 
    selected="$REST_DATA/collection/general/$selected_name"
fi

mkdir -p $selected



REST_WINDOW="$(tmux list-windows | grep  rest | egrep -o '^[^:]+' )"


if [ -z "${REST_WINDOW}" ]; then
    tmux new-window -d -n rest -c $selected nvim


    REST_WINDOW="$(TMUX list-windows | grep  rest | egrep -o '^[^:]+' )"
fi



tmux select-window -t $REST_WINDOW 




