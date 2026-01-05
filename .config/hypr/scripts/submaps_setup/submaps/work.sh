#!/bin/bash

source ~/.config/hypr/scripts/submaps_setup/submap.sh work

add_bind "t" "focusworkspaceoncurrentmonitor, name:terminal-work" "Go to Terminal"
add_bind "b" "focusworkspaceoncurrentmonitor, name:browser-work" "Go to Browser"
add_bind "s" "focusworkspaceoncurrentmonitor, name:slack-work" "Go to Slack"
add_bind "p" "focusworkspaceoncurrentmonitor, name:povio" "Go to Povio"
add_bind "g" "submap, google-work" "Google"



