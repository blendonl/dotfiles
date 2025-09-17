#!/bin/bash

source ~/.config/hypr/scripts/submap.sh normal bindr=super_l,super_l


add_bind "escape" "exec, $submap reset" "Exit submap"
add_bind "return" "exec, alacritty" "Open terminal"
add_bind "s" "exec, sherlock" "Search"
add_bind "v" "exec, cliphist list | wofi -dmenu | cliphist decode | wl-copy" "Paste clipboard"
add_bind "m" "submap, mouse" "Mouse"
add_bind "n" "submap, notes" "Notes"
add_bind "i" "submap, notification" "Notifications"
add_bind "p" "submap, power" "Power"
add_bind "r" "submap, record" "Record"
add_bind "w" "submap, window" "Window management"      


all_allowed

echo "$TEXT" > ~/.config/hypr/hyprland/keybinds/$SUBMAP.conf

source ~/.config/hypr/scripts/source_submap.sh




