#!/bin/bash

source ~/.config/hypr/scripts/submaps_setup/submap.sh window



add_bind "F" "fullscreen" "Fullscreen"
add_bind "D" "fullscreenstate, 0 2 toggle " "Fake fullscreen"
add_bind "C" "killactive" "Toggle split"
add_bind "P" "submap, reserved_space" "Reserved Space"
add_bind "Space" "togglesplit" "Toggle split"

