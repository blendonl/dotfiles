#!/bin/bash

source ~/.config/hypr/scripts/submaps_setup/submap.sh notification

add_bind "escape" "exec, $submap reset" "Exit submap"
add_bind "a" "exec, dunstctl close-all" "Close all notifications"
add_bind "c" "exec, dunstctl close" "Close current notification"
add_bind "h" "exec, dunstctl history-pop" "Show last notification"
add_bind "v" "exec, dunstctl history-pop-all" "Show all notifications"
add_bind "p" "exec, dunstctl set-paused toggle" "Pause/unpause notifications"
add_bind "m" "exec, dunstctl set-mute toggle" "Mute/unmute notifications"   



