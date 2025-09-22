#!/bin/bash

source ~/.config/hypr/scripts/submaps_setup/submap.sh window



add_bind "escape" "exec, $submap reset" "Exit submap"   
add_bind "F" "exec, fullscreenstate" "Fullscreen"
add_bind "D" "exec, fullscreen" "Disable fullscreen"
add_bind "I" "exec, fullscreenstate -1" "Fullscreen on inactive"
add_bind "T" "exec, togglefloating" "Toggle floating"
add_bind "P" "exec, pin" "Pin window"
add_bind "Space" "exec, togglesplit" "Toggle split"
    

