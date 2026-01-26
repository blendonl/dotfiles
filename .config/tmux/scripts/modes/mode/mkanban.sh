#!/bin/bash

source $HOME/.config/tmux/scripts/modes/mode.sh


create_mode "mkanban-mode" "k"

add_bind "n" 'run-shell "tmux display-popup -E -h 50% -w 80% mkanban task create"' "Create new task"
add_bind "p" 'run-shell "~/.config/tmux/scripts/mkanban/current.sh"' "Show current task"
add_bind "c" 'run-shell "~/.config/tmux/scripts/mkanban/checkout.sh"' "Checkout task"
add_bind "a" 'run-shell "~/.config/tmux/scripts/mkanban/agenda.sh"' "Show agenda"


save_mode


