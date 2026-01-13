#!/bin/bash


BINDS=""
MODE=""


add_bind() {
    local key=$1
    local function=$2

    local bind="bind -T $MODE $key $function"

    BINDS+="$bind\n" 
}


create_mode() {
    MODE=$1
    KEY=$2

    local bind="bind $2 switch-client -T $MODE"

    BINDS+="$bind\n"
}


save_mode() {
    mkdir -p $HOME/.config/tmux/modes

    local file="$HOME/.config/tmux/modes/$MODE.conf"

    touch $file


    echo -e "$BINDS" > $file
    chmod +x $file

    BINDS=""
}
