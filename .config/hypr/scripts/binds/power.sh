#!/bin/bash

source ~/.config/hypr/scripts/binds/shared.sh

submap_name="Exec" 
key_pairs='[
    {"key":"t","value":"New Task"},
    {"key":"k","value":"Mkanban"},
    {"key":"s","value":"notes"},
    {"key":"g","value":"notes"},
    {"key":"d","value":"notes"}
]'

show_eww_indicator "$key_pairs" "$submap_name" 
