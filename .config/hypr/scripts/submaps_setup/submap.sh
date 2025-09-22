#!/bin/bash

source ~/.config/hypr/scripts/submaps_setup/shared.sh


SUBMAP="$1"
BIND="$2"
shift
ALLOWED_KEYS=("$@")



ALL_KEYS=(a b c d e f g h i j k l m n o p q r s t u v w x y z space tab return escape backspace delete left right up down home end pageup pagedown insert f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 grave minus equal backslash bracketleft bracketright semicolon apostrophe comma period slash shift_l shift_r ctrl_l ctrl_r alt_l alt_r super_l super_r caps_lock num_lock scroll_lock print pause menu kp_divide kp_multiply kp_subtract kp_add kp_enter kp_decimal)
ALL_USED_KEYS=()
key_pairs=$'[\n]'
show_indicator="~/.config/hypr/scripts/eww/indicator.sh"
indicators="~/.config/eww/indicators/$SUBMAP.json"
exit_submap="hyprctl dispatch submap reset && eww close list_indicator"


is_allowed() {
    local key="$1"
    for allowed in "${ALL_USED_KEYS[@]}"; do
        [[ "$key" == "$allowed" ]] && return 0
    done
    return 1
}

all_allowed() {
for key in "${ALL_KEYS[@]}"; do
    if ! is_allowed "$key"; then
        TEXT=$(echo -e "$TEXT" | sed '$d')
        TEXT+=$'\n\n'
        TEXT+="bind = , $key, pass"
        TEXT+=$'\n'
        TEXT+=$'\nsubmap = reset'
    fi

done
}

add_bind() {
    local key="$1"
    local function="$2"
    local description="$3"
    TEXT=$(echo -e "$TEXT" | sed '$d')

    if [[ ! $function == *"submap"* ]] then
        TEXT+=$(echo -e "\n\nbind=, $key, exec, $exit_submap\n")
        TEXT+=$(echo -e "\nbind=, $key, $function\n")
    elif [[ $function == *"submap, reset"* ]] then
        TEXT+=$(echo -e "\n\nbind=, $key, $function\n")
    else 
        indicator_submap=$(echo $function | sed 's/submap, //g')
        TEXT+=$(echo -e "\n\nbind=, $key, exec, $show_indicator $indicator_submap\n")
        TEXT+=$(echo -e "\nbind=, $key, $function\n")
    fi


    TEXT+=$(echo -e "\nsubmap = reset")

    ALL_USED_KEYS+=("$key")

    add_key_pair "$key" "$description"
}

add_key_pair() {
    local key="$1"
    local description="$2"
    key_pairs=$(echo -e "$key_pairs" | sed '$d')

    local line_count=$(echo -e "$key_pairs" | wc -l)
    if [ "$line_count" -gt 1 ]; then
        key_pairs+=$(echo -e ",\n {\"key\":\"$key\",\"value\":\"$description\"}\n]")
    else
        key_pairs+=$(echo -e "\n {\"key\":\"$key\",\"value\":\"$description\"}\n]")
    fi

    mkdir -p ~/.config/eww/indicators

    echo -e "$key_pairs" > ~/.config/eww/indicators/$SUBMAP.json

}


TEXT=''

if [ ! -z "$BIND" ]; then
    TEXT+=$(echo -e "\n$BIND, exec, $show_indicator $SUBMAP")
    TEXT+=$(echo -e "\n$BIND, submap, $SUBMAP\n \n")
fi
TEXT+=$(echo -e "\nsubmap= $SUBMAP\n\ntmp")

