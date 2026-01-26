#!/bin/sh

OPTIONS=("no" "no" "yes")

RESULT=$(printf "%s\n" "${OPTIONS[@]}" | wofi --show dmenu --height=150 --width=10 )

if [ $RESULT = "yes" ]; then 
  systemctl poweroff; 
fi
