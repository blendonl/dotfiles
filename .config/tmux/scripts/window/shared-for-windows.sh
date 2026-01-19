#!/usr/bin/env bash

WINDOW_NAME="$1"
WINDOW="$(tmux list-windows | grep  $WINDOW_NAME | egrep -o '^[^:]+' )"
ACTIVE_WINDOW="$(tmux list-windows | grep  "*" | egrep -o '^[^:]+' )"
PANE_COUNT=$(tmux list-panes | egrep -o '^[^:]+' | sort -n | tail -n 1) 
INDEX=$(tmux show-environment "$WINDOW_NAME"_INDEX 2>/dev/null | cut -d= -f2)
WINDOW_PATH="#{pane_current_path}"




if [ -n "$3" ]; then
    WINDOW_PATH="$3"

    selected_name=$(tmux display-message -p '#S')
    selected_path=$(tmux display-message -p '#{pane_current_path}')



    if [[ "$selected_path" == *"work"* ]]; then
        selected="$WINDOW_PATH/work${selected_path##*work}"
    elif [[ "$selected_path" == *"personal"* ]]; then
        selected="$WINDOW_PATH/personal${selected_path##*personal}"
    elif [[ "$selected_name" =~ ^[0-9]+$ ]]; then
        selected="$WINDOW_PATH/general/"
    else 
        selected="$WINDOW_PATH/general/$selected_name"
    fi


    mkdir -p $selected

    WINDOW_PATH="$selected"


fi
