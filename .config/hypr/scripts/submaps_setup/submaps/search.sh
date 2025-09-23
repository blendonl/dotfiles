#!/bin/bash

source ~/.config/hypr/scripts/submaps_setup/submap.sh search


add_bind "a" "exec, sherlock" "    Search"             
add_bind "v" "exec, cliphist list | wofi -dmenu | cliphist decode | wl-copy" "Paste clipboard" 
    
