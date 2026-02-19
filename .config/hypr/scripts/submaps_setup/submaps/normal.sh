#!/bin/bash

source ~/.config/hypr/scripts/submaps_setup/submap.sh normal bindr=super_l,super_l


add_bind "return" "exec, alacritty" "Open terminal"
add_bind "m" "submap, monitor" "Monitor"
add_bind "s" "submap, search" "Search"
add_bind "c" "submap, mouse" "Click"
add_bind "n" "submap, notes" "Notes"
add_bind "i" "submap, notification" "Notifications"
add_bind "p" "submap, power" "Power"
add_bind "r" "submap, record" "Record"
add_bind "g" "submap, go" "Go to"
add_bind "w" "submap, window" "Window management"      
add_bind "TAB" "movecurrentworkspacetomonitor, +1" "Move Workspace to Monitor"
add_bind "space" "focusworkspaceoncurrentmonitor, previous_per_monitor" "Go to previous workspace" "e"






