#!/bin/bash

source ~/.config/hypr/scripts/submaps_setup/shared.sh


SUBMAP="$1"
EXPRESSION="$2"
BIND="bind"
shift




ALL_USED_KEYS=()
key_pairs=$'[\n]'
show_indicator="~/.config/hypr/scripts/eww/indicator.sh"
indicators="~/.config/eww/indicators/$SUBMAP.json"
exit_submap="eww close-all"




add_bind() {
    local key="$1"
    local function="$2"
    local description="$3"
    BIND="bind$4"
    TEXT=$(echo -e "$TEXT" | sed '$d')


    if [[ ! $function == *"submap"* ]] then
        TEXT+=$(echo -e "\n\n$BIND=, $key, exec, $exit_submap\n")
        TEXT+=$(echo -e "\n$BIND=, $key, $function\n")
        TEXT+=$(echo -e "\n$BIND=, $key, submap, reset\n\n")
    elif [[ $key == *"escape"* ]] then
        TEXT+=$(echo -e "\n\n$BIND=, $key, exec, $exit_submap\n")
        TEXT+=$(echo -e "\n$BIND=, $key, submap, reset\n\n")
    else 
        indicator_submap=$(echo $function | sed 's/submap, //g')
        TEXT+=$(echo -e "\n\n$BIND=, $key, exec, $show_indicator $indicator_submap\n")
        TEXT+=$(echo -e "\n$BIND=, $key, $function\n\n")
    fi

    TEXT+=$(echo -e "\n\nsubmap = reset")




    ALL_USED_KEYS+=("$key")

    if  [[ !  $key == "escape" ]] then
        add_key_pair "$key" "$description"
    fi


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

if [ ! -z "$EXPRESSION" ]; then
    TEXT+=$(echo -e "\n$EXPRESSION, exec, $show_indicator $SUBMAP")
    TEXT+=$(echo -e "\n$EXPRESSION, submap, $SUBMAP\n \n")

fi

TEXT+=$(echo -e "\nsubmap= $SUBMAP\n\n")
TEXT+=$(echo -e "\n\n$BIND=, catchall, exec, $exit_submap \n")
TEXT+=$(echo -e "\n$BIND=, catchall, submap, reset\n")

