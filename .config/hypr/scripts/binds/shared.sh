#!/bin/bash

EWW_WIN_NAME="list_indicator"

show_eww_indicator() {
    local key_pairs="$1"
    local submap_name="$2"
    
    if eww active-windows | grep -q "${EWW_WIN_NAME}"; then
        eww close "${EWW_WIN_NAME}"
    fi

    ACTIVE_MONITOR_ID=$(hyprctl monitors -j | jq '.[] | select(.focused == true) | .id')
    eww update key_pairs="${key_pairs}" submap_name="${submap_name}"
    eww open "${EWW_WIN_NAME}" --screen "${ACTIVE_MONITOR_ID}"
}

