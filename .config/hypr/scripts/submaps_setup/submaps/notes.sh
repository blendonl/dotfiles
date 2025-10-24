#!/bin/bash


source ~/.config/hypr/scripts/submaps_setup/submap.sh notes 

scripts_path="$HOME/.config/hypr/scripts"

add_bind "n" "exec, $scripts_path/mkanban/script-new.sh" "New Task"
add_bind "k" "exec, $scripts_path/mkanban/script.sh" "Mkanban"
add_bind "t" "exec, $scripts_path/mkanban/current_in_progress.sh" "Current Task"       
add_bind "c" "exec, $scripts_path/notes/checkout-to-tasks.sh" "Checkout to Task"
add_bind "d" "exec, $scripts_path/notes/daily-note.sh" "Daily Note"




