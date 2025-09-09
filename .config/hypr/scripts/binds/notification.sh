#!/bin/bash

source ~/.config/hypr/scripts/binds/shared.sh




submap_name="Exec" 
key_pairs='[
    {"key":"a","value":"Close All"},
    {"key":"c","value":"Close"},
    {"key":"h","value":"History"},
    {"key":"m","value":"Mute Toggle"}
    {"key":"p","value":"Pause Toggle"},
    {"key":"v","value":"History All"},
]'

show_eww_indicator "$key_pairs" "$submap_name" 
