#!/usr/bin/env bash


attached_sessions=$(tmux list-sessions | grep "(attached)" | cut -d':' -f1)

if [ -z "$attached_sessions" ]; then
    selected_name=0    
else 
    session_count=$(tmux list-sessions | grep "(attached)" | cut -d':' -f1 | wc -l)

    if [ "$session_count" -eq 1 ]; then

        selected_name=$(tmux run "tmux display-message -p '#S'")
        selected_path=$(tmux run "tmux display-message -p '#{pane_current_path}'")

    else
        selected_session=$(tmux list-sessions | grep '(attached)' | cut -d':' -f1 | sed 's/\b[0-9]\{1,2\}\b/general/g' | wofi --show dmenu)
        
        
        if [ -n "$selected_session" ]; then
            selected_name=$(tmux run -t $selected_session.1 "tmux display-message -p '#S'")
            selected_path=$(tmux run -t "$selected_session.1" "tmux display-message -p '#{pane_current_path}'")

        else
            echo "No session selected"
            exit 1
        fi
    fi
fi


EDITOR=neovide mkanban --show-current-task --board $selected_name --column "in-progress" &> /dev/null &



# ./$HOME/.config/hypr/scripts/window/reserved-space.sh

