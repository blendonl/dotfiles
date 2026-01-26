#!/bin/bash
# Get the active window size from Hyprctl
WIDTH=$(hyprctl activewindow -j | jq '.size[0]')
HEIGHT=$(hyprctl activewindow -j | jq '.size[1]')

echo $WIDTH $HEIGHT

# Push those dimensions to Waydroid
waydroid shell wm size "${WIDTH}x${HEIGHT}"
