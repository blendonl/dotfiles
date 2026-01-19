#!/usr/bin/env bash


source $HOME/.config/tmux/scripts/window/shared-for-windows.sh $1 $2



if [ "$INDEX" -gt "-1" ]; then


    CURRENT_WINDOW_NAME=$(tmux display-message -p -t $ACTIVE_WINDOW '#W')

    echo $INDEX

    
    tmux break-pane -s $ACTIVE_WINDOW.$INDEX -d -n $WINDOW_NAME

    tmux rename-window -t $ACTIVE_WINDOW "$CURRENT_WINDOW_NAME"

    tmux set-environment "$WINDOW_NAME"_INDEX "-1"

    echo $ACTIVE_WINDOW.$INDEX
    echo $WINDOW_NAME
    echo $CURRENT_WINDOW_NAME
    echo $WINDOW_PATH

    exit 0

fi

echo 4




if [ -z "$2" ]; then
  tmux join-pane -v -l 30% -t $ACTIVE_WINDOW.$PANE_COUNT -s $WINDOW.0
else 
  tmux join-pane $2 -l 30% -t $ACTIVE_WINDOW.$PANE_COUNT -s $WINDOW.0
fi


PANE_COUNT=$(tmux list-panes | egrep -o '^[^:]+' | sort -n | tail -n 1) 
tmux set-environment "$WINDOW_NAME"_INDEX "$PANE_COUNT"











