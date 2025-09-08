#!/bin/bash

# Simple script to disable keys in Hyprland submap using hyprctl
# Usage: ./simple_disable.sh [submap_name] [allowed_keys...]


SUBMAP="$1"
shift
ALLOWED_KEYS=("$@")

[[ $SUBMAP == "reset" ]] && hyprctl reload && hyprctl dispatch submap reset && eww close list_indicator && exit 0 

ALL_KEYS=(a b c d e f g h i j k l m n o p q r s t u v w x y z 1 2 3 4 5 6 7 8 9 0 space tab)

is_allowed() {
    local key="$1"
    for allowed in "${ALLOWED_KEYS[@]}"; do
        [[ "$key" == "$allowed" ]] && return 0
    done
    return 1
}

hyprctl keyword submap $SUBMAP

for key in "${ALL_KEYS[@]}"; do
    if ! is_allowed "$key"; then
        hyprctl keyword bind ",${key},pass," 
    fi
done


hyprctl dispatch submap "$SUBMAP"



