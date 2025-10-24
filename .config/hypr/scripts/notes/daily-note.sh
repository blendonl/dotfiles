

NOTE_PATH="$HOME/notes/daily"


mkdir -p "$NOTE_PATH"

# array of today tomorrow and yesterday
days=("Today" "Tomorrow" "Yesterday")

# use fzf to select one of the days and if something that doesnt exist is selected echo it and exit
day="$(printf "%s\n" "${days[@]}" | rofi -dmenu --prompt="Select day: " --height=5 --layout=reverse --border --ansi)" 


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


if [ ! -f "$NOTE_PATH/$date_str.md" ]; then
    echo "---
id: \"$date_str\"
aliases: []
tags:
  - daily-notes
---" >> "$NOTE_PATH/$date_str.md"
fi  

neovide "$NOTE_PATH/$date_str.md"


