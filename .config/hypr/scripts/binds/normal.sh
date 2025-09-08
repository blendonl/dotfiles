#!/bin/bash

source ~/.config/hypr/scripts/binds/shared.sh
submap_name="Exec" 
key_pairs='[
    {"key":"i","value":"Notifications"},
    {"key":"m","value":"Mouse"},
    {"key":"n","value":"Notes"},
    {"key":"p","value":"Power"},
    {"key":"r","value":"Record"},
    {"key":"return","value":"Alacritty"},
    {"key":"s","value":"Run"},
    {"key":"shift+c","value":"Kill"},
    {"key":"shift+return","value":"Toggle terminal scratchpad"},
    {"key":"shift+tab","value":"Swap monitor"},
    {"key":"tab","value":"Focus monitor"},
    {"key":"v","value":"Paste"},
    {"key":"w","value":"Window"}
]'

show_eww_indicator "$key_pairs" "$submap_name" 
