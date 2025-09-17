#!/bin/bash

source ~/.config/hypr/scripts/submap.sh record



add_bind "escape" "exec, $submap reset" "Exit submap"
add_bind "a" "exec, sherlock; exec, $submap reset" "    Search"             
add_bind "v" "exec, cliphist list | wofi -dmenu | cliphist decode | wl-copy; exec, $submap reset" "Paste clipboard" 
    

all_allowed

echo "$TEXT" > ~/.config/hypr/hyprland/keybinds/$SUBMAP.conf

source ~/.config/hypr/scripts/source_submap.sh
