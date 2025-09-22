#!/bin/bash

source ~/.config/hypr/scripts/submaps_setup/shared.sh

key_pairs=$(cat /home/notpc/.config/eww/indicators/$1.json)
submap_name="$1"




show_eww_indicator "$key_pairs"  "$submap_name" 
