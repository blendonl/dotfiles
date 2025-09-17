#!/bin/bash


files=($(ls ~/.config/hypr/scripts/binds))

for file in "${files[@]}"; do
    filename="${file%.*}"


    source ~/.config/hypr/scripts/binds/$file

done













