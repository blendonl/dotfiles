#!/usr/bin/env bash


alacritty --class=checkout -e bash -c "mkanban list  | fzf --with-nth=2 --delimiter=$'\t' --preview 'bat --color=always -p --language=markdown --theme-dark=base16  {1}'"









