#!/bin/bash


source ~/.config/hypr/scripts/submap.sh notes 


add_bind "escape" "exec, $submap reset" "Exit submap"
add_bind "t" "exec, NOTE_PATH=/home/notpc/notes  /home/notpc/.config/hypr/scripts/mkanban/script-new.sh" "New Task"
add_bind "k" "exec, NOTE_PATH=/home/notpc/notes /home/notpc/.config/mkanban/script.sh" "Mkanban"
add_bind "s" "exec, alacritty -e nvim /home/notpc/notes/ai.md" "notes"
add_bind "g" "exec, alacritty -e nvim /home/notpc/notes/ai.md" "notes"
add_bind "d" "exec, alacrity -e nvim /home/notpc/notes/ai.md" "notes"       


all_allowed

echo "$TEXT" > ~/.config/hypr/hyprland/keybinds/$SUBMAP.conf

source ~/.config/hypr/scripts/source_submap.sh


