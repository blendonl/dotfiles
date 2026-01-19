#!/bin/bash

source $HOME/.config/tmux/scripts/modes/mode.sh


create_mode "magenda-mode" "k"

add_bind "n" 'run-shell "tmux display-popup -E -h 50% -w 80% mkanban task create"'
add_bind "p" 'run-shell "~/.config/tmux/scripts/mkanban/current.sh"'
add_bind "c" 'run-shell "~/.config/tmux/scripts/mkanban/checkout.sh"'
add_bind "a" 'run-shell "~/.config/tmux/scripts/mkanban/agenda.sh"'


save_mode


