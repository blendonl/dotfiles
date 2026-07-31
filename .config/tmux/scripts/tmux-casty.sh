#!/usr/bin/env zsh

# Source zsh configuration to get PATH and environment
source ~/.zshrc 2>/dev/null || true

# Get the current pane's working directory
PWD=$(tmux display-message -p '#{pane_current_path}')

# Default URL
CASTY_URL="localhost:3000"

# Check for .env file in the current directory
if [ -f "$PWD/.env" ]; then
    # Try to extract a full URL first
    ENV_URL=$(grep -iE '^(URL|BASE_URL|APP_URL|VITE_APP_URL|NEXT_PUBLIC_URL|SITE_URL)=' "$PWD/.env" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"' | tr -d "'" | xargs)

    if [ -n "$ENV_URL" ]; then
        CASTY_URL="$ENV_URL"
    else
        # Fall back to HOST + PORT
        ENV_HOST=$(grep -iE '^(HOST|HOSTNAME|SERVER_HOST)=' "$PWD/.env" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"' | tr -d "'" | xargs)
        ENV_PORT=$(grep -iE '^PORT=' "$PWD/.env" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"' | tr -d "'" | xargs)

        HOST="${ENV_HOST:-localhost}"
        PORT="${ENV_PORT:-3000}"
        CASTY_URL="${HOST}:${PORT}"
    fi
fi

# Determine if casty should open with http:// prefix
# If the URL already has a scheme, use it as-is; otherwise add http://
if ! echo "$CASTY_URL" | grep -qiE '^[a-z][a-z0-9+.-]*://'; then
    CASTY_URL="http://${CASTY_URL}"
fi

# Use the shared window script pattern
source "$HOME/.config/tmux/scripts/window/shared-for-windows.sh" CASTY "casty $CASTY_URL"

if [ -z "${WINDOW}" ]; then
    tmux new-window -n "$WINDOW_NAME" -c "$PWD" "zsh -c 'casty $CASTY_URL'"
    WINDOW="$(tmux list-windows | grep "$WINDOW_NAME" | egrep -o '^[^:]+')"
fi

tmux select-window -t "$WINDOW"
