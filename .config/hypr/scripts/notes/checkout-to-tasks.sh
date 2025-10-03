#!/usr/bin/env bash


ghostty --title="mkanban" --command="mkanban list  | fzf --with-nth=2 --delimiter=$'\t' --preview 'bat --color=always -p --language=markdown --theme-dark=base16  {1}'"









