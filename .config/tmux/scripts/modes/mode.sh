#!/bin/bash


BINDS=""
MODE=""
WHICH_KEY=""


add_bind() {
    local key=$1
    local function=$2
    local description=$3

    local bind="bind -T $MODE $key $function"

    BINDS+="$bind\n" 
    
    if [[ -n "$description" ]]; then
        WHICH_KEY+="$key: $description\n"
    fi
}


create_mode() {
    MODE=$1
    KEY=$2

    bind="bind -T custom-prefix $2 run-shell -b \"\$HOME/.config/tmux/scripts/modes/show-which-key.sh $MODE\" \\; switch-client -T $MODE"

    BINDS+="$bind\n"
}


save_mode() {
    mkdir -p $HOME/.config/tmux/modes

    local file="$HOME/.config/tmux/modes/$MODE.conf"

    touch $file


    echo -e "$BINDS" > $file
    chmod +x $file

    if [[ -n "$WHICH_KEY" ]]; then
        local which_key_file="$HOME/.config/tmux/modes/$MODE-which-key.txt"
        echo -e "$WHICH_KEY" > $which_key_file
    fi

    BINDS=""
    WHICH_KEY=""
}
