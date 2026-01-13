#!/bin/bash

source $HOME/.config/tmux/scripts/modes/mode.sh


create_mode "ai-mode" "a"

add_bind "o" 'run-shell "~/.config/tmux/scripts/window/create-window.sh OPENCODE opencode"'
add_bind "c" 'run-shell "~/.config/tmux/scripts/window/create-window.sh CLAUDE claude"'


save_mode


