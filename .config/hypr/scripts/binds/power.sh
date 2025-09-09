#!/bin/bash

source ~/.config/hypr/scripts/binds/shared.sh


    bind = , Return, exec, hyprctl dispatch exit
    bind = , Return, exec, $exit_submap

    bind = , R, exec  , hyprctl dispatch reboot
    bind = , R, exec, $exit_submap

    bind = , S, exec  , hyprctl dispatch suspend
    bind = , S, exec, $exit_submap

    bind = , L, exec  , hyprlock
    bind = , L, exec, $exit_submap

    bind = , P, exec  , hyprctl dispatch poweroff
    bind = , P, exec, $exit_submap

    bind = , ESCAPE, exec, $exit_submap

submap_name="Exec" 
key_pairs='[
    {"key":"Return","value":"Exit"}
    {"key":"l","value":"Log Out"},
    {"key":"p","value":"Power Off"},
    {"key":"r","value":"Reboot"},
    {"key":"s","value":"Suspend"},
]'

show_eww_indicator "$key_pairs" "$submap_name" 
