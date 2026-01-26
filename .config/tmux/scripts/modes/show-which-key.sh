#!/bin/bash

TABLE=${1:-custom-prefix}
WHICH_KEY_DIR="$HOME/.config/tmux/modes/generated"

if [[ "$TABLE" == "prefix" ]] || [[ "$TABLE" == "custom-prefix" ]]; then
    WHICH_KEY_FILE="$WHICH_KEY_DIR/custom-prefix-which-key.txt"

    if [[ ! -f "$WHICH_KEY_FILE" ]]; then
        tmux list-keys -T custom-prefix 2>/dev/null | awk -F'custom-prefix' '{if(NF>1) print $2}' | awk '{printf "%-15s %s\n", $1, substr($0, index($0,$2))}' > "$WHICH_KEY_FILE"
    fi
else
    WHICH_KEY_FILE="$WHICH_KEY_DIR/${TABLE}-which-key.txt"

    if [[ ! -f "$WHICH_KEY_FILE" ]]; then
        "$HOME/.config/tmux/scripts/modes/generate-which-key.sh" > /dev/null 2>&1
    fi
fi

if [[ -f "$WHICH_KEY_FILE" ]]; then

    # Build menu items array
    menu_items=()
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            # Extract key and description (assuming format: "key    description")
            key=$(echo "$line" | awk '{print $1}')
            desc=$(echo "$line" | cut -d' ' -f2-)
            menu_items+=("$desc" "" "run-shell 'tmux display-message \"Key: $key\"'")
        fi
    done < "$WHICH_KEY_FILE"

    # Display menu with all items
    if [[ ${#menu_items[@]} -gt 0 ]]; then
        tmux display-menu -T "Key Bindings" -x R -y P -s 50 "${menu_items[@]}"
    fi
else
    tmux display-message "No keybindings found for table: $TABLE"
fi
