#!/bin/bash

source ~/.config/hypr/scripts/submaps_setup/submap.sh power

add_bind "Return" "exec, hyprctl dispatch exit" "Exit Hyprland"
add_bind "r" "exec, systemctl reboot" "Reboot"
add_bind "s" "exec, systemctl suspend" "Suspend"
add_bind "l" "exec, hyprlock; exec"   "Lock screen"
add_bind "p" "exec, systemctl poweroff; exec" "Power off"          




