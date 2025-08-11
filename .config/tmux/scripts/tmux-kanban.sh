#!/usr/bin/env bash

handle_error() {
    echo "Error occurred on line $LINENO with exit code $?"
    exit 1
}

trap 'handle_error' ERR



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

path="$selected/kanban.md";


mkdir -p $selected

if [ ! -f $path ]; then
    cp /home/notpc/.config/taskell/template.md $path
fi

    echo $path
taskell $path 2> /home/notpc/.config/tmux/log.err





