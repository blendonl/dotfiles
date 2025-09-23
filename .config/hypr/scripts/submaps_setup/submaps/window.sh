#!/bin/bash

source ~/.config/hypr/scripts/submaps_setup/submap.sh window



add_bind "F" "fullscreenstate" "Fullscreen"
add_bind "D" "fullscreen" "Disable fullscreen"
add_bind "I" "fullscreenstate " "Fullscreen on inactive"
add_bind "T" "togglefloating" "Toggle floating"
add_bind "C" "killactive" "Toggle split"
add_bind "P" "submap, reserved_space" "Reserved Space"
add_bind "Space" "togglesplit" "Toggle split"

