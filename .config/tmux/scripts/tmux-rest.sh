#!/usr/bin/env bash

selected_name=$(tmux display-message -p '#S')
selected_path=$(tmux display-message -p '#{pane_current_path}')



mkdir -p $selected


REST_WINDOW="$(tmux list-windows | grep  rest | egrep -o '^[^:]+' )"



if [ -z "${REST_WINDOW}" ]; then
    tmux new-window -d -n rest -c $selected nvim index.http

    REST_WINDOW="$(tmux list-windows | grep  rest | egrep -o '^[^:]+' )"
fi


tmux select-window -t $REST_WINDOW 

