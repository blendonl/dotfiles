#!/usr/bin/env bash

SEARCH_PATHS=(
    ~/.config/nvim
    ~/dotfiles/.config
    ~/work
    ~/notes
    ~/personal
    /mnt/data/work
    /mnt/data/personal/dotfiles/.config
    /mnt/data/personal
    /mnt/data/notes
)

CONFIG_ROOTS=(
    /mnt/data/personal/dotfiles/.config
    /home/notpc/dotfiles/.config
)

MONOREPO_SUBDIRS=(apps packages)

find_sessions() {
    local config_roots_arg
    config_roots_arg=$(IFS=,; echo "${CONFIG_ROOTS[*]}")

    local script_dir
    script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

    perl "$script_dir/find-sessions.pl" \
        "$config_roots_arg" \
        "$(IFS=,; echo "${MONOREPO_SUBDIRS[*]}")" \
        "${SEARCH_PATHS[@]}"
}

resolve_session_name() {
    local dir=$1

    if [[ -d "$dir/.git" ]]; then
        basename "$dir" | tr . _
        return
    fi

    local parent=$dir
    while [[ "$parent" != "/" ]]; do
        parent=$(dirname "$parent")
        if [[ -d "$parent/.git" ]]; then
            echo "$(basename "$parent")/$(basename "$dir")" | tr . _
            return
        fi
    done

    basename "$dir" | tr . _
}

selected=${1:-$(find_sessions | fzf-tmux -p --no-extended)}
[[ -z "$selected" ]] && exit 0

selected_name=$(resolve_session_name "$selected")

if [[ -z "$TMUX" ]] && [[ -z "$(pgrep tmux)" ]]; then
    tmux new-session -s "$selected_name" -c "$selected"
    exit 0
fi

tmux has-session -t="$selected_name" 2>/dev/null \
    || tmux new-session -ds "$selected_name" -c "$selected"

tmux switch-client -t "$selected_name"
