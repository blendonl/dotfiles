#!/bin/bash

FILTER_KEYWORD=$1
DISPATCH=$2

all_workspaces=$(grep -oP '(name|special):[^,]*' ~/.config/hypr/hyprland/hyprland-workspaces.conf)

if [ -n "$FILTER_KEYWORD" ]; then
  filtered_workspaces=$(echo "$all_workspaces" | grep "$FILTER_KEYWORD")
else
  filtered_workspaces="$all_workspaces"
fi

not_sorted=$(echo "$filtered_workspaces" | sed 's/^name://')

display_names=$(echo "$filtered_workspaces" | sed 's/^name://' | sed 's/^special://' | sed 's/[[:space:]]*$//' | sort)



selected=$(printf '%s\n' "$display_names" | wofi --show dmenu --sort-order=default)
[ -z "$selected" ] && exit 0

workspace=$(echo "$filtered_workspaces" | grep "$selected")

hyprctl dispatch $DISPATCH "$workspace"









