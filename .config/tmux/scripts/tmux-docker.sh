#!/usr/bin/env bash

DOCKER_WINDOW="$(tmux list-windows | grep  docker | egrep -o '^[^:]+' )"
ACTIVE_WINDOW="$(tmux list-windows | grep  "*" | egrep -o '^[^:]+' )"

LIST_PANES="$(tmux list-panes -F '#F' )"
PANE_COUNT="$(echo "${LIST_PANES}" | wc -l | bc)"





if [ "${PANE_COUNT}" -gt 1 ] && [ -z "${DOCKER_WINDOW}" ]; then
    
    tmux break-pane -s $ACTIVE_WINDOW.1 -d -n docker

    exit 0
fi

if [ -z "${DOCKER_WINDOW}" ]; then
    tmux new-window -d -n docker -c "#{pane_current_path}" 

    DOCKER_WINDOW="$(tmux list-windows | grep  docker | egrep -o '^[^:]+' )"
fi


tmux join-pane -h -l 25% -t $ACTIVE_WINDOW -s $DOCKER_WINDOW.0




