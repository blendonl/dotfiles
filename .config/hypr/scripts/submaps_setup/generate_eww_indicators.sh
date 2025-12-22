#!/bin/bash

INDICATORS_DIR="$HOME/.config/eww/indicators"
OUTPUT_FILE="$HOME/.config/eww/indicators.yuck"

echo "" > "$OUTPUT_FILE"

for json_file in "$INDICATORS_DIR"/*.json; do
    if [ ! -f "$json_file" ]; then
        continue
    fi

    echo json_file: $json_file

    submap_name=$(basename "$json_file" .json)

    num_items=$(jq 'length' "$json_file")

    items_per_column=5
    num_columns=$(( (num_items + items_per_column - 1) / items_per_column ))

    if [ $num_columns -gt 4 ]; then
        num_columns=4
        items_per_column=$(( (num_items + num_columns - 1) / num_columns ))
    fi

    declare -a col_widths

    for col in $(seq 0 3); do
        max_key_length=0
        start_idx=$((col * items_per_column))
        end_idx=$(((col + 1) * items_per_column - 1))

        if [ $start_idx -lt $num_items ]; then
            for idx in $(seq $start_idx $end_idx); do
                if [ $idx -lt $num_items ]; then
                    key=$(jq -r ".[$idx].key" "$json_file")
                    key_length=${#key}
                    if [ $key_length -gt $max_key_length ]; then
                        max_key_length=$key_length
                    fi
                fi
            done
        fi

        col_widths[$col]=$((max_key_length * 20))
    done

    for col in $(seq 0 3); do
        cat >> "$OUTPUT_FILE" << EOF
(defwidget key-pair-${submap_name}-col${col} [pair]
  (box :class "item" :orientation "horizontal" :space-evenly false
    (label :class "key" :text "\${pair.key}" :halign "start" :width ${col_widths[$col]})
    (label :class "separator" :text " → " :halign "center" :width 50)
    (label :class "value" :text "\${pair.value}" :halign "start" :width 130)))

EOF
    done

    cat >> "$OUTPUT_FILE" << EOF
(defwindow list_indicator_${submap_name}
  :monitor monitor
  :geometry (geometry :x "0%" :y "0%" :width "100%" :anchor "bottom center")
  :stacking "overlay"
  :focusable false
  :namespace "list-hints"
  (box :class "list-popup" :orientation "vertical" :space-evenly false
    (box :class "list" :orientation "horizontal" :space-evenly false
EOF

    for col in $(seq 0 3); do
        echo "      (box :orientation \"vertical\" :width 200" >> "$OUTPUT_FILE"

        start_idx=$((col * items_per_column))
        end_idx=$(((col + 1) * items_per_column - 1))

        if [ $start_idx -lt $num_items ]; then
            for idx in $(seq $start_idx $end_idx); do
                if [ $idx -lt $num_items ]; then
                    key=$(jq -r ".[$idx].key" "$json_file")
                    value=$(jq -r ".[$idx].value" "$json_file")
                    echo "        (key-pair-${submap_name}-col${col} :pair \`{\"key\": \"$key\", \"value\": \"$value\"}\`)" >> "$OUTPUT_FILE"
                fi
            done
        fi

        echo ")" >> "$OUTPUT_FILE"
    done

    cat >> "$OUTPUT_FILE" << 'EOF'
)
    (label :halign "center" :class "exit-keys" :text "Esc - Exit")))

EOF
done

echo "Generated $OUTPUT_FILE"
