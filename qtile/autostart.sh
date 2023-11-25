#!/bin/sh

picom &
# discord &
xrandr --output eDP-1 --mode 1920x1200 --brightness 0.5 &
xrandr --output eDP-1 --mode 2560x1600 &
xrandr --output eDP-1 --mode 1920x1200 &
# dunst &
