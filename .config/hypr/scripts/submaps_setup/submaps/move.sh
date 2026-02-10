#!/bin/bash

source ~/.config/hypr/scripts/submaps_setup/submap.sh move


add_bind "w" "exec, ~/.config/hypr/scripts/workspace/get-workspace.sh work movetoworkspace" "Work"
add_bind "p" "exec, ~/.config/hypr/scripts/workspace/get-workspace.sh personal movetoworkspace" "Personal"

