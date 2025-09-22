#!/bin/bash


source ~/.config/hypr/scripts/submaps_setup/submap.sh record


add_bind "escape" "exec, $submap reset" "Exit submap"
add_bind "v" "exec, hyprshot -m region --clipboard-only; exec, $submap reset" "Screenshot region to clipboard"
add_bind "s" "exec, grim -g \"\$(slurp -d)\" - | wl-copy; exec, $submap reset" "Screenshot region to clipboard"
add_bind "p" "exec, hyprpicker -a; exec, $submap reset" "Screenshot with picker"    


