#!/bin/bash


MODES_DIR="$HOME/.config/tmux/scripts/modes/mode"

MODES=($(ls $MODES_DIR/*.conf 2>/dev/null | xargs -n1 basename))

for MODE in "${MODES[@]}"; do
    source "$MODES_DIR/$MODE"
done




SOURCED_MODES_DIR="$HOME/.config/tmux/modes"

SOURCED_MODES=($(ls $SOURCED_MODES_DIR/*.conf 2>/dev/null | xargs -n1 basename))


TEXT=""

echo "" > $HOME/.config/tmux/mode.conf
for SOURCED_MODE in "${SOURCED_MODES[@]}"; do
  echo -e "source $SOURCED_MODES_DIR/$SOURCED_MODE" > $HOME/.config/tmux/mode.conf
done


