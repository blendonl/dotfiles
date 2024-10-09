#!/bin/bash

kitties=$(hyprctl -j clients | sed -z 's/{//g; s/}//g; s/\[//g; s/\]//g; s/ //g; s/"at":/move/g; s/"size":/size/g; s/,\n/ /g; s/move\n/move /g; s/\n size\n/; size /g; s/\n\n/\n/g' | grep -v "^$")

if [[ -n "$kitties" ]]; then
  echo -e $kitties | sed "s/ move/\nmove/g"  > ~/.savedkittens
fi
