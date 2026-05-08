local r = require('keybinds.submaps.registry')

local NEW_NOTE = "EDITOR='neovide --wayland_app_id=new-to-do' mkanban task create"

local KANBAN_BOARD = 'alacritty --class=mkanban -e bash -c mkanban'

local CURRENT_TASK = [[
EDITOR=neovide mkanban --board foragr-be --show-current-task --column "in-progress" >/dev/null 2>&1 &
]]

local CHECKOUT_TO_TASKS = [[
alacritty --class=checkout -e bash -c "mkanban list | fzf --with-nth=2 --delimiter=$'\t' --preview 'bat --color=always -p --language=markdown --theme-dark=base16 {1}'"
]]

local DAILY_NOTE = [[
NOTE_PATH="$HOME/notes/daily"
mkdir -p "$NOTE_PATH"
day=$(printf '%s\n' Today Tomorrow Yesterday | rofi -dmenu -p "Select day: ") || exit 0
case "$day" in
  Today)     date_str=$(date +%Y-%m-%d) ;;
  Tomorrow)  date_str=$(date -d tomorrow +%Y-%m-%d) ;;
  Yesterday) date_str=$(date -d yesterday +%Y-%m-%d) ;;
  *) exit 0 ;;
esac
file="$NOTE_PATH/$date_str.md"
if [ ! -f "$file" ]; then
  printf -- '---\nid: "%s"\naliases: []\ntags:\n  - daily-notes\n---\n' "$date_str" > "$file"
fi
neovide "$file"
]]

local reserved_space = require('keybinds.submaps.reserved_space')

local function current_task()
  hl.dsp.exec_cmd(CURRENT_TASK)()
  hl.timer(function() reserved_space.add() end, { timeout = 1000, type = 'oneshot' })
end

r.define('notes', 'reset', function(bind)
  bind('n', hl.dsp.exec_cmd(NEW_NOTE),         { description = 'New note' })
  bind('k', hl.dsp.exec_cmd(KANBAN_BOARD),     { description = 'Kanban board' })
  bind('t', current_task,                      { description = 'Current task' })
  bind('c', hl.dsp.exec_cmd(CHECKOUT_TO_TASKS),{ description = 'Checkout to tasks' })
  bind('d', hl.dsp.exec_cmd(DAILY_NOTE),       { description = 'Daily note' })
  bind('escape', hl.dsp.submap('reset'),       { description = 'Cancel' })
  bind('catchall', hl.dsp.submap('reset'))
end)
