#!/bin/bash


source ~/.config/hypr/scripts/submaps_setup/submap.sh notes 


add_bind "n" "exec, NOTE_PATH=/home/notpc/notes  /home/notpc/.config/hypr/scripts/mkanban/script-new.sh" "New Task"
add_bind "k" "exec, NOTE_PATH=/home/notpc/notes /home/notpc/.config/mkanban/script.sh" "Mkanban"
add_bind "t" "exec, /home/notpc/.config/hypr/scripts/mkanban/current_in_progress.sh" "Current Task"       
add_bind "c" "exec, $HOME/.config/hypr/scripts/notes/checkout-to-tasks.sh" "Checkout to Task"




