#!/usr/bin/env bash



TASK=$(mkanban task list --output fzf | fzf-tmux -p --no-extended | mkanban task checkout )












