#!/usr/bin/env bash


EDITOR=neovide mkanban --board foragr-be --show-current-task --column "in-progress" &> /dev/null &

sleep 1

$HOME/.config/hypr/scripts/window/reserved-space.sh

