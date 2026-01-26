#!/usr/bin/env zsh

# Source zsh configuration to get PATH and environment
source ~/.zshrc 2>/dev/null || true

source $HOME/.config/tmux/scripts/window/shared-for-windows.sh $1 $2



if [ "$INDEX" -gt "-1" ]; then


    CURRENT_WINDOW_NAME=$(tmux display-message -p -t $ACTIVE_WINDOW '#W')


    # Get the original window for this specific pane
    ORIGINAL_WINDOW=$(tmux show-environment "${WINDOW_NAME}_PANE_${INDEX}" 2>/dev/null | cut -d= -f2)
    if [ -z "$ORIGINAL_WINDOW" ]; then
        ORIGINAL_WINDOW="$WINDOW_NAME"
    fi
    
    tmux break-pane -s $ACTIVE_WINDOW.$INDEX -d -n $ORIGINAL_WINDOW

    tmux rename-window -t $ACTIVE_WINDOW "$CURRENT_WINDOW_NAME"

    tmux set-environment "$WINDOW_NAME"_INDEX "-1"
    tmux set-environment "${WINDOW_NAME}_PANE_${INDEX}" ""

    exit 0

fi





# Get current panes in source window before joining
SOURCE_PANES=$(tmux list-panes -t $WINDOW | egrep -o '^[^:]+' | sort -n)

if [ -z "$2" ]; then
  tmux join-pane -v -l 30% -t $ACTIVE_WINDOW.$PANE_COUNT -s $WINDOW.0
else 
  tmux join-pane $2 -l 30% -t $ACTIVE_WINDOW.$PANE_COUNT -s $WINDOW.0
fi

PANE_COUNT=$(tmux list-panes | egrep -o '^[^:]+' | sort -n | tail -n 1) 

# Store mapping of each joined pane to its original window
PANE_INDEX=0
for source_pane in $SOURCE_PANES; do
    tmux set-environment "${WINDOW_NAME}_PANE_${PANE_INDEX}" "$WINDOW"
    PANE_INDEX=$((PANE_INDEX + 1))
done

tmux set-environment "$WINDOW_NAME"_INDEX "$PANE_COUNT"











