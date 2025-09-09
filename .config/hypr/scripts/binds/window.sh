#!/bin/bash

source ~/.config/hypr/scripts/binds/shared.sh


submap_name="Exec" 
key_pairs='[
    {"key":"f","value":"Full Screen"},
    {"key":"d","value":"Window Full Screen"},
    {"key":"i","value":"Fake Full Screen"},
    {"key":"t","value":"Toggle Floating"},
    {"key":"p","value":"Pin"}
    {"key":"Space","value":"Toggle Split"}
]'

show_eww_indicator "$key_pairs" "$submap_name" 
