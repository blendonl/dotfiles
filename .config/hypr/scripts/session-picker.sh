#!/usr/bin/env bash
# Session picker for Hyprland — launched asynchronously via hl.dsp.exec_cmd().
# Discovers projects, presents them in rofi, and activates the chosen session.
#
# Modes:
#   session-picker.sh           Full interactive picker (rofi)
#   session-picker.sh --list    Print session paths to stdout and exit
#
# Debug log: /tmp/hypr-session-picker.log


SEARCH_PATHS=(
    ~/.config/nvim
    ~/dotfiles/.config
    ~/work
    ~/notes
    ~/personal
    /mnt/data/work
    /mnt/data/personal/dotfiles/.config
    /mnt/data/personal
    /mnt/data/notes
)

CONFIG_ROOTS=(
    /mnt/data/personal/dotfiles/.config
    /home/notpc/dotfiles/.config
)

MONOREPO_SUBDIRS=(apps packages)

MAX_DEPTH=6
STATE_FILE="$HOME/.local/state/hypr/session.json"
CACHE_FILE=/tmp/hypr-session-picker-cache.txt
LOG=/tmp/hypr-session-picker.log

find_sessions() {
    local config_roots_arg
    config_roots_arg=$(IFS=,; echo "${CONFIG_ROOTS[*]}")

    local script_dir
    script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

    perl "$HOME/.config/hypr/scripts/find-sessions.pl" \
        "$config_roots_arg" \
        "$(IFS=,; echo "${MONOREPO_SUBDIRS[*]}")" \
        "${SEARCH_PATHS[@]}"
}

resolve_session_name() {
    local dir=$1

    if [[ -d "$dir/.git" ]]; then
        basename "$dir" | tr . _
        return
    fi

    local parent=$dir
    while [[ "$parent" != "/" ]]; do
        parent=$(dirname "$parent")
        if [[ -d "$parent/.git" ]]; then
            echo "$(basename "$parent")/$(basename "$dir")" | tr . _
            return
        fi
    done

    basename "$dir" | tr . _
}



# --- setup_default_workspaces -------------------------------------------
# Register per-session workspace rules via hyprctl for the given session.
# Usage: setup_default_workspaces <session_name> <session_dir>
#-------------------------------------------------------------------------
setup_default_workspaces() {
  local session_name=$1
  local session_dir=$2
  local file="$HOME/.config/hypr/session/default_workspaces.lua"

  [[ -f "$file" ]] || { echo "setup_default_workspaces: $file not found" >&2; return 1; }
  [[ -n "$session_name" ]] && [[ -n "$session_dir" ]] || {
    echo "usage: setup_default_workspaces <name> <dir>" >&2; return 1
  }

  lua - "$file" "$session_name" "$session_dir" <<'LUA_EOF'
    local ws = dofile(arg[1])
    local name = arg[2]
    local dir  = arg[3]

    for _, w in ipairs(ws) do
      local on_created = w.on_created_empty(dir, name)
      local ws_name    = "'name:" .. name .. "/" .. w.suffix .. "'"

      -- Build value as:  name:..., on_created_empty:...
      local value = "workspace=".. ws_name .. ", on_created_empty='" .. on_created .. "'"

      -- Single-quote the value for the shell, escaping any embedded single quotes
      local escaped = value:gsub("'", "'\\''")


      local ev = 'hl.workspace_rule({' .. escaped .. '})'

      os.execute("hyprctl eval '" .. ev .. "'")
    end
LUA_EOF
}






selected=${1:-$(find_sessions | rofi -dmenu -p "Session: " -theme dmenu-custom)}
[[ -z "$selected" ]] && exit 0

name=$(resolve_session_name "$selected")


# --- JSON helpers (standalone Lua, same logic as session/state.lua) -------
# The embedded Lua script reads the existing multi-session JSON, adds or
# updates the selected session (preserving last_workspace if re-selecting
# the same session), sets it as last_active, writes back, and prints the
# old last_workspace to stdout — all in one atomic read-modify-write.
#-------------------------------------------------------------------------
focus_ws_type=$(lua - "$name" "$selected" <<'LUA_EOF'
  -- Minimal JSON escape (same as session/state.lua)
  local function json_escape(s)
    return s:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t')
  end
  local function json_unescape(s)
    s = s:gsub('\\\\', '\x00')
    s = s:gsub('\\"', '"'):gsub('\\n', '\n'):gsub('\\r', '\r'):gsub('\\t', '\t')
    return s:gsub('\x00', '\\')
  end

  --- Extract a JSON-encoded string starting at the opening quote.
  --- Returns position after closing quote, and unescaped content.
  local function extract_json_string(s, pos)
    if not pos then return nil end
    local start = s:find('"', pos)
    if not start then return nil end
    local i = start + 1
    while i <= #s do
      local c = s:sub(i, i)
      if c == '\\' then i = i + 2
      elseif c == '"' then
        return i + 1, json_unescape(s:sub(start + 1, i - 1))
      else i = i + 1 end
    end
    return nil
  end

  --- Find a JSON key and extract its string value.
  local function find_string_value(s, key, pos)
    local pattern = '"' .. key .. '":%s*"'
    local _, after = s:find(pattern, pos or 1)
    if not after then return nil end
    return extract_json_string(s, after)
  end

  local STATE_FILE = os.getenv('HOME') .. '/.local/state/hypr/session.json'
  local name = arg[1]
  local dir  = arg[2]

  -- Read existing state -------------------------------------------------
  local data = { sessions = {} }
  local f = io.open(STATE_FILE, 'r')
  if f then
    local raw = f:read('*a')
    f:close()
    if raw and raw ~= '' then
      -- Detect legacy single-session format
      if raw:match('^%s*{"name":') then
        local _, n = find_string_value(raw, 'name', 1)
        local _, d = find_string_value(raw, 'dir', 1)
        local _, w = find_string_value(raw, 'last_workspace', 1)
        if n and d then
          data.sessions[n] = { dir = d, last_workspace = w or nil }
          data.last_active = n
        end
      else
        -- Parse multi-session format
        local _, la = find_string_value(raw, 'last_active', 1)
        if la then data.last_active = la end
        local ses_start, ses_brace = raw:find('"sessions":%s*{')
        if ses_start then
          local depth, ses_end = 0, nil
          for i = ses_brace, #raw do
            local c = raw:sub(i, i)
            if c == '{' then depth = depth + 1
            elseif c == '}' then
              depth = depth - 1
              if depth == 0 then ses_end = i; break end
            end
          end
          if ses_end then
            local block = raw:sub(ses_brace + 1, ses_end - 1)
            local pos = 1
            while pos <= #block do
              local after_key, key = extract_json_string(block, pos)
              if not after_key or not key then break end
              local _, brace_pos = block:find('%s*:%s*{', after_key)
              if not brace_pos then break end
              local d2, inner_end = 0, nil
              for i = brace_pos, #block do
                local c = block:sub(i, i)
                if c == '{' then d2 = d2 + 1
                elseif c == '}' then
                  d2 = d2 - 1
                  if d2 == 0 then inner_end = i; break end
                end
              end
              if not inner_end then break end
              local sr = block:sub(brace_pos, inner_end)
              local _, d = find_string_value(sr, 'dir', 1)
              local _, w = find_string_value(sr, 'last_workspace', 1)
              if d and key then
                data.sessions[key] = { dir = d, last_workspace = w or nil }
              end
              pos = inner_end + 1
              while pos <= #block do
                local c = block:sub(pos, pos)
                if c == ',' or c == ' ' or c == '\n' or c == '\r' or c == '\t' then
                  pos = pos + 1
                else break end
              end
            end
          end
        end
      end
    end
  end

  -- Determine old last_workspace for this session -----------------------
  local old_ws = nil
  if data.sessions[name] then
    old_ws = data.sessions[name].last_workspace
  end

  -- Update state ---------------------------------------------------------
  data.sessions[name] = { dir = dir, last_workspace = old_ws }
  data.last_active = name

  -- Write back -----------------------------------------------------------
  os.execute('mkdir -p "' .. STATE_FILE:match('^(.*)/') .. '"')
  local parts = { '{"sessions":{' }
  local first = true
  for n, s in pairs(data.sessions) do
    if not first then parts[#parts + 1] = ',' end
    first = false
    parts[#parts + 1] = '"' .. json_escape(n) .. '":{"dir":"' .. json_escape(s.dir) .. '"'
    if s.last_workspace then
      parts[#parts + 1] = ',"last_workspace":"' .. json_escape(s.last_workspace) .. '"'
    end
    parts[#parts + 1] = '}'
  end
  parts[#parts + 1] = '}'
  if data.last_active then
    parts[#parts + 1] = ',"last_active":"' .. json_escape(data.last_active) .. '"'
  end
  local out = io.open(STATE_FILE, 'w')
  if out then
    out:write(table.concat(parts) .. '}\n')
    out:close()
  end

  -- Print old last_workspace (or default "browser") for bash to capture
  print(old_ws or 'browser')
LUA_EOF
)
#-------------------------------------------------------------------------

setup_default_workspaces "$name" "$selected"

echo "$(date): focusing workspace name:$name/$focus_ws_type" >>"$LOG"
hyprctl dispatch "hl.dsp.focus({workspace=\"name:$name/$focus_ws_type\"})" >>"$LOG" 2>&1 || {
    echo "$(date): hyprctl FAILED with exit code $?" >>"$LOG"
}

