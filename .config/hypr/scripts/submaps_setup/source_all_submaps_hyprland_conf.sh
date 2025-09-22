#!/bin/bash


files=($(ls ~/.config/hypr/hyprland/keybinds))
text=$'\n'

for file in "${files[@]}"; do
    filename="${file%.*}"

    text+=$(echo -e "\nsource = ~/.config/hypr/hyprland/keybinds/$filename.conf\n")


done

echo "$text" > ~/.config/hypr/hyprland/submaps.conf



if ! grep -q "source = ~/.config/hypr/hyprland/submaps.conf" ~/.config/hypr/hyprland.conf; then
    echo -e "\n\nsource = ~/.config/hypr/hyprland/submaps.conf" >> ~/.config/hypr/hyprland.conf
fi













