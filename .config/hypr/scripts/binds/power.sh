#!/bin/bash

source ~/.config/hypr/scripts/submap.sh power

add_bind "escape" "exec, $submap reset" "Exit submap"
add_bind "Return" "exec, hyprctl dispatch exit; exec, $exit_submap" "Exit Hyprland"
add_bind "r" "exec, hyprctl dispatch reboot; exec, $exit_submap" "Reboot"
add_bind "s" "exec      , hyprctl dispatch suspend; exec, $exit_submap" "Suspend"
add_bind "l" "exec, hyprlock; exec, $exit_submap"   "Lock screen"
add_bind "p" "exec, hyprctl dispatch poweroff; exec, $exit_submap" "Power off"          

all_allowed

echo "$TEXT" > ~/.config/hypr/hyprland/keybinds/$SUBMAP.conf

source ~/.config/hypr/scripts/source_submap.sh


