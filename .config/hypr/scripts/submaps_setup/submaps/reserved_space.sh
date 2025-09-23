#!/bin/bash

source ~/.config/hypr/scripts/submaps_setup/submap.sh reserved_space



add_bind "p" "exec, $HOME/.config/hypr/scripts/window/reserved-space.sh" "Pin"
add_bind "u" "exec, $HOME/.config/hypr/scripts/window/remove-reserved-space.sh" "Remove reserved space"

