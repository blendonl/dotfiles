#!/bin/bash

source $HOME/.config/tmux/scripts/modes/mode.sh


create_mode "ai-mode" "a"

add_bind "o" 'run-shell "~/.config/tmux/scripts/window/create-window.sh OPENCODE opencode"' "Open OpenCode window"
add_bind "c" 'run-shell "~/.config/tmux/scripts/window/create-window.sh CLAUDE claude"' "Open Claude window"
add_bind "x" 'run-shell "~/.config/tmux/scripts/window/create-window.sh CODEX codex"' "Open Codex window"


save_mode


