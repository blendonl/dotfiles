#!/bin/bash


res_pos=600

active_monitor=$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) | .name')




if grep -q "monitor = $active_monitor, addreserved, 0, 0, 0, $res_pos" ~/.config/hypr/hyprland/reserved-space.conf; then
    source ~/.config/hypr/scripts/window/remove-reserved-space.sh
fi


echo "monitor = $active_monitor, addreserved, 0, 0, 0, $res_pos" > ~/.config/hypr/hyprland/reserved-space.conf


if ! grep -q "source = ~/.config/hypr/hyprland/reserved-space.conf" ~/.config/hypr/hyprland.conf; then
    echo -e "\n\nsource = ~/.config/hypr/hyprland/reserved-space.conf" >> ~/.config/hypr/hyprland.conf
fi



width=$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) | .width')
height=$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) | .height')
x=$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) | .x')
y=$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) | .y')
scale=$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) | .scale')


actual_width=$(printf "%.0f" $(echo "$width / $scale" | bc -l))
move=$(printf "%.0f" $(echo "$actual_width - $res_pos" | bc -l))
res_pos=$(printf "%.0f" $(echo "$res_pos * 100 / $actual_width" | bc -l))




hyprctl dispatch setfloating
hyprctl dispatch movewindowpixel exact $move 0, activewindow
hyprctl dispatch resizewindowpixel exact $res_pos% 100%, activewindow
hyprctl dispatch pin











