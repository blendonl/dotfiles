#!/bin/bash

source ~/.config/hypr/scripts/binds/shared.sh


submap_name="Exec" 
key_pairs='[
    {"key":"p","value":"Picker"},
    {"key":"s","value":"Screen Shot"},
    {"key":"v","value":"Screen Shot"},
]'

show_eww_indicator "$key_pairs" "$submap_name" 
