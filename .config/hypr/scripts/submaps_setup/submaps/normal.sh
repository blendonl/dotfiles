#!/bin/bash

source ~/.config/hypr/scripts/submaps_setup/submap.sh normal bindr=super_l,super_l


add_bind "return" "exec, alacritty" "Open terminal"
add_bind "1" "focusworkspaceoncurrentmonitor, name:random" "Go to workspace 1"
add_bind "2" "focusworkspaceoncurrentmonitor, name:browser" "Go to workspace 2"
add_bind "3" "focusworkspaceoncurrentmonitor, name:terminal" "Go to workspace 3"
add_bind "4" "focusworkspaceoncurrentmonitor, name:ai" "Go to workspace 4"
add_bind "5" "focusworkspaceoncurrentmonitor, name:gh" "Go to workspace 5"
add_bind "6" "focusworkspaceoncurrentmonitor, name:discord" "Go to workspace 6"
add_bind "7" "focusworkspaceoncurrentmonitor, name:slack" "Go to workspace 7"
add_bind "8" "focusworkspaceoncurrentmonitor, name:music" "Go to workspace 8"
add_bind "9" "focusworkspaceoncurrentmonitor, name:yu" "Go to workspace 9"
add_bind "0" "focusworkspaceoncurrentmonitor, name:games" "Go to workspace 10"
add_bind "s" "submap, search" "Search"
add_bind "m" "submap, mouse" "Mouse"
add_bind "n" "submap, notes" "Notes"
add_bind "i" "submap, notification" "Notifications"
add_bind "p" "submap, power" "Power"
add_bind "r" "submap, record" "Record"
add_bind "w" "submap, window" "Window management"      





