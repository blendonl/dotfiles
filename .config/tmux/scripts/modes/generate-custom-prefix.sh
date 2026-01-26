#!/bin/bash

OUTPUT_FILE="$HOME/.config/tmux/custom-prefix.conf"

echo "# Auto-generated custom prefix table with which-key support" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

tmux list-keys -T prefix | while IFS= read -r line; do
    if [[ $line =~ bind-key[[:space:]]+(-r[[:space:]]+)?-T[[:space:]]+prefix[[:space:]]+([^[:space:]]+)[[:space:]]+(.+)$ ]]; then
        repeat="${BASH_REMATCH[1]}"
        key="${BASH_REMATCH[2]}"
        command="${BASH_REMATCH[3]}"

        echo "bind-key ${repeat}-T custom-prefix $key $command" >> "$OUTPUT_FILE"
    fi
done

echo "" >> "$OUTPUT_FILE"
echo "Generated custom prefix table in $OUTPUT_FILE"
