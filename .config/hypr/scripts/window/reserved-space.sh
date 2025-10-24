#!/bin/bash


res_pos=500



if grep -q "monitor = , addreserved, 0, 0, 0, $res_pos" ~/.config/hypr/hyprland/reserved-space.conf; then
    source ~/.config/hypr/scripts/window/remove-reserved-space.sh
fi


echo "monitor = , addreserved, 0, 0, 0, $res_pos" > ~/.config/hypr/hyprland/reserved-space.conf


if ! grep -q "source = ~/.config/hypr/hyprland/reserved-space.conf" ~/.config/hypr/hyprland.conf; then
    echo -e "\n\nsource = ~/.config/hypr/hyprland/reserved-space.conf" >> ~/.config/hypr/hyprland.conf
fi



active_monitor=$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) | .name')
width=$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) | .width')
height=$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) | .height')
x=$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) | .x')
y=$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) | .y')
scale=$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) | .scale')





move=$((x + ((width ) - res_pos)))
res_pos=$((res_pos * 100 / (width)))



hyprctl dispatch setfloating
hyprctl dispatch movewindowpixel exact $move 0, activewindow
hyprctl dispatch resizewindowpixel exact $res_pos% 100%, activewindow
hyprctl dispatch pin











