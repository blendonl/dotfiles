#!/bin/bash

EWW_WIN_NAME="list_indicator"

show_eww_indicator() {
    local submap_name="$1"
    
    eww close-all


    ACTIVE_MONITOR_ID=$(hyprctl monitors -j | jq '.[] | select(.focused == true) | .id')
    eww open "${EWW_WIN_NAME}_$submap_name" --screen "${ACTIVE_MONITOR_ID}"
}

