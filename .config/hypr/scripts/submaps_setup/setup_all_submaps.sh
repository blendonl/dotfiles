#!/bin/bash


files=($(ls ~/.config/hypr/scripts/submaps_setup/submaps/))

for file in "${files[@]}"; do
    filename="${file%.*}"

    source ~/.config/hypr/scripts/submaps_setup/submaps/$file


    add_bind "escape" "exec, submap reset" "Exit submap"

    echo "$TEXT" > ~/.config/hypr/hyprland/keybinds/$SUBMAP.conf

done

source ~/.config/hypr/scripts/submaps_setup/source_all_submaps_hyprland_conf.sh
source ~/.config/hypr/scripts/submaps_setup/generate_eww_indicators.sh













