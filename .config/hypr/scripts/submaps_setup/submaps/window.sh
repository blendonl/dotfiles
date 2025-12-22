#!/bin/bash

source ~/.config/hypr/scripts/submaps_setup/submap.sh window



add_bind "F" "fullscreen" "Fullscreen"
add_bind "D" "fullscreenstate, 0 1 toggle " "Fake fullscreen"
add_bind "C" "killactive" "Kill active"
add_bind "P" "submap, reserved_space" "Reserved Space"
add_bind "M" "submap, move" "Move window"
add_bind "Space" "togglesplit" "Toggle split"



