#!/bin/bash


source ~/.config/hypr/scripts/submaps_setup/submap.sh record


add_bind "v" "exec, hyprshot -m region --clipboard-only" "Screenshot region to clipboard"
add_bind "s" "exec, hyprshot -m region" "Screenshot region to clipboard"
add_bind "p" "exec, hyprpicker -a" "Screenshot with picker"    


