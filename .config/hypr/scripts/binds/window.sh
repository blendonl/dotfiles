#!/bin/bash

source ~/.config/hypr/scripts/submap.sh record



add_bind "escape" "exec, $submap reset" "Exit submap"   
add_bind "F" "exec, hyprctl dispatch fullscreenstate; exec, $exit_submap" "Fullscreen"
add_bind "D" "exec, hyprctl dispatch fullscreen; exec, $exit_submap" "Disable fullscreen"
add_bind "I" "exec, hyprctl dispatch fullscreenstate -1; exec, $exit_submap" "Fullscreen on inactive"
add_bind "T" "exec, hyprctl dispatch togglefloating; exec, $exit_submap" "Toggle floating"
add_bind "P" "exec, hyprctl dispatch pin; exec, $exit_submap" "Pin window"
add_bind "Space" "exec, hyprctl dispatch togglesplit; exec, $exit_submap" "Toggle split"
    

all_allowed

echo "$TEXT" > ~/.config/hypr/hyprland/keybinds/$SUBMAP.conf

source ~/.config/hypr/scripts/source_submap.sh
