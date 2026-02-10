#!/bin/bash

source ~/.config/hypr/scripts/submaps_setup/submap.sh go

# add_bind "w" "submap, work" "Work"
# add_bind "p" "submap, personal" "Personal"
# add_bind "g" "submap, gaming" "Gaming"
# add_bind "c" "submap, content" "Content"
add_bind "w" "exec, ~/.config/hypr/scripts/workspace/get-workspace.sh work focusworkspaceoncurrentmonitor " "Work"
add_bind "p" "exec, ~/.config/hypr/scripts/workspace/get-workspace.sh personal focusworkspaceoncurrentmonitor " "Personal"





