#!/bin/bash


res_pos=500

width=$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) | .width')
height=$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) | .height')
x=$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) | .x')
y=$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) | .y')
scale=$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) | .scale')





move=$((x + ((width / 2) - res_pos)))
move_cursor=$((move + (res_pos / 2)))


hyprctl dispatch movecursor $move_cursor 500

hyprctl dispatch focuswindow floating











