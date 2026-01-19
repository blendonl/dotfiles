#!/usr/bin/env bash






days=("Today" "Tomorrow" "Yesterday")

day="$(printf "%s\n" "${days[@]}" | fzf-tmux -p --no-extended --prompt="Select Day: ")" 


if [[ "$day" == "Today" ]]; then
    date_str=$(date +%Y-%m-%d)
elif [[ "$day" == "Tomorrow" ]]; then
    date_str=$(date -d "tomorrow" +%Y-%m-%d)
elif [[ "$day" == "Yesterday" ]]; then
    date_str=$(date -d "yesterday" +%Y-%m-%d)
elif [[ "$day" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    date_str="$day"
else
    echo "Invalid selection"
    exit 1
fi



DATE=$(magenda datepicker --fzf --no-extended)


echo $date_str

TASK=$(mkanban task list --output fzf --column to-do --all-boards | fzf-tmux -p --no-extended | magenda schedule --date "$date_str" )












