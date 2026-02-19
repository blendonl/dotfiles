#!/bin/bash


MODES_DIR="$HOME/.config/tmux/scripts/modes/mode"

MODES=($(ls $MODES_DIR/*.sh 2>/dev/null | xargs -r -n1 basename))

for MODE in "${MODES[@]}"; do
    source "$MODES_DIR/$MODE"
done




SOURCED_MODES_DIR="$HOME/.config/tmux/modes"

SOURCED_MODES=($(ls $SOURCED_MODES_DIR/*.conf 2>/dev/null | xargs -r -n1 basename))




echo "" > $HOME/.config/tmux/mode.conf

for SOURCED_MODE in "${SOURCED_MODES[@]}"; do
  TEXT+=$(echo -e "\nsource $SOURCED_MODES_DIR/$SOURCED_MODE\n")
  TEXT+=$(echo -e "\n\n\n\n") 
done



printf "$TEXT" > $HOME/.config/tmux/mode.conf

