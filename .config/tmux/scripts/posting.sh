#!/usr/bin/env bash

selected_name=$(tmux display-message -p '#S')
selected_path=$(tmux display-message -p '#{pane_current_path}')


if [[ "$selected_path" == *"work"* ]]; then
    selected="$POSTING_DATA/collection/work/$selected_name"
elif [[ "$selected_path" == *"personal"* ]]; then
    selected="$POSTING_DATA/collection/personal/$selected_name"
elif [[ "$selected_name" =~ ^[0-9]+$ ]]; then
    selected="$POSTING_DATA/collection/general/"
else 
    selected="$POSTING_DATA/collection/general/$selected_name"
fi

mkdir -p $selected



POSTING_WINDOW="$(tmux list-windows | grep  posting | egrep -o '^[^:]+' )"


if [ -z "${POSTING_WINDOW}" ]; then
    tmux new-window -d -n posting -c "#{pane_current_path}" "EDITOR=nvim posting --collection $selected"


    POSTING_WINDOW="$(tmux list-windows | grep  posting | egrep -o '^[^:]+' )"
fi



tmux select-window -t $POSTING_WINDOW 




