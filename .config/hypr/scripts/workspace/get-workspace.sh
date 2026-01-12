#!/bin/bash



workspace=$(cat ~/.config/hypr/hyprland/hyprland-workspaces.conf  | grep -oP '(name|special):[^,]*' |  wofi --show dmenu)

hyprctl dispatch focusworkspaceoncurrentmonitor $workspace









