#!/bin/bash

OUTPUT_DIR="$HOME/.config/tmux/modes/generated"
mkdir -p "$OUTPUT_DIR"

format_key() {
    local key="$1"
    key="${key//C-/Ctrl+}"
    key="${key//M-/Alt+}"
    echo "$key"
}

format_action() {
    local action="$1"

    action="${action//-/ }"
    action="${action//_/ }"

    action="$(echo "$action" | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')"

    echo "$action"
}

generate_for_table() {
    local table="$1"
    local output_file="$OUTPUT_DIR/${table}-which-key.txt"

    > "$output_file"

    tmux list-keys -T "$table" | while IFS= read -r line; do
        if [[ $line =~ bind-key[[:space:]]+(-r[[:space:]]+)?-T[[:space:]]+${table}[[:space:]]+([^[:space:]]+)[[:space:]]+(.+)$ ]]; then
            local key="${BASH_REMATCH[2]}"
            local action="${BASH_REMATCH[3]}"

            [[ "$key" == "MouseDown"* ]] && continue
            [[ "$key" == "MouseDrag"* ]] && continue
            [[ "$key" == "MouseUp"* ]] && continue
            [[ "$key" == "WheelUp"* ]] && continue
            [[ "$key" == "WheelDown"* ]] && continue
            [[ "$key" == "DoubleClick"* ]] && continue
            [[ "$key" == "TripleClick"* ]] && continue

            if [[ $action =~ ^([a-z-]+) ]]; then
                action=$(format_action "${BASH_REMATCH[1]}")
            fi

            key=$(format_key "$key")

            printf "%-15s %s\n" "$key" "$action" >> "$output_file"
        fi
    done

    if [[ -s "$output_file" ]]; then
        echo "Generated: $output_file"
    else
        rm -f "$output_file"
    fi
}

TABLES=("custom-prefix" "ai-mode" "mkanban-mode" "magenda-mode")

for table in "${TABLES[@]}"; do
    generate_for_table "$table"
done

echo "Which-key files generated in $OUTPUT_DIR"
