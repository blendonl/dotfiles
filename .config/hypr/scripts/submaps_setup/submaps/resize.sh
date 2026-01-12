#!/bin/bash

source ~/.config/hypr/scripts/submaps_setup/submap.sh resize

add_bind "h" "resizeactive, -10 0" "Resize width left" "e"
add_bind "j" "resizeactive, 0 10" "Resize height right" "e"
add_bind "k" "resizeactive, 0 -10" "Resize height" "e"
add_bind "l" "resizeactive, 10 0" "Resize width" "e"


