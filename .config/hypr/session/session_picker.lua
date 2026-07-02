-- session_picker.lua — session discovery & selection
-- Discovery delegates to session-picker.sh --list (single io.popen) instead
-- of walking the filesystem from Lua (which would require hundreds of shell
-- spawns).  Name resolution uses io.open (fopen, no shell) to check for
-- .git directories — essentially instant compared to io.popen.

-- ============================================================
-- Configuration
-- ============================================================

local SCRIPT = os.getenv('HOME') .. '/.config/hypr/scripts/session-picker.sh'
local CACHE_FILE = '/tmp/hypr-session-picker-cache.txt'

-- ============================================================
-- In-memory caches (populated once at startup)
-- ============================================================

local _sessions_cache = nil  -- array of full paths
local _name_cache = nil      -- map: full path → session name

-- ============================================================
-- find_sessions — read from cache file if it exists, otherwise
-- delegate to the shell script (single io.popen, ~1s).  The
-- cache file is written by the shell script on first invocation
-- and persists across boots.
-- ============================================================

local function find_sessions()
  if _sessions_cache then
    return _sessions_cache
  end

  local sessions = {}

  -- Try the cache file first (< 1ms, survives reboots)
  local f = io.open(CACHE_FILE, 'r')
  if f then
    for line in f:lines() do
      if line ~= '' then
        sessions[#sessions + 1] = line
      end
    end
    f:close()
    if #sessions > 0 then
      _sessions_cache = sessions
      return sessions
    end
  end

  -- Cache miss — call the shell script (single io.popen, ~1s)
  local p = io.popen(SCRIPT .. ' --list 2>/dev/null')
  if not p then
    _sessions_cache = sessions
    return sessions
  end

  for line in p:lines() do
    if line ~= '' then
      sessions[#sessions + 1] = line
    end
  end
  p:close()

  _sessions_cache = sessions
  return sessions
end

-- ============================================================
-- resolve_session_name — pure Lua, uses io.open (fopen, not
-- a shell spawn) to check for .git directories.
-- ============================================================

local function resolve_session_name(dir_path)
  -- Check if the directory itself is a git repo
  local f = io.open(dir_path .. '/.git/HEAD')
  if f then
    f:close()
    local name = dir_path:match('[^/]+$')
    return name:gsub('%.', '_')
  end

  -- Walk up to find a parent that is a git repo
  local dir = dir_path
  while dir ~= '/' do
    local parent = dir:match('^(.*)/[^/]+$') or '/'
    f = io.open(parent .. '/.git/HEAD')
    if f then
      f:close()
      local parent_name = parent:match('[^/]+$')
      local dir_name = dir_path:match('[^/]+$')
      return (parent_name .. '/' .. dir_name):gsub('%.', '_')
    end
    dir = parent
  end

  -- Fallback: just the basename
  local name = dir_path:match('[^/]+$')
  return name:gsub('%.', '_')
end

-- ============================================================
-- Cached name lookup (populated on first use)
-- ============================================================

local function get_name_map()
  if _name_cache then
    return _name_cache
  end
  _name_cache = {}
  for _, path in ipairs(find_sessions()) do
    _name_cache[path] = resolve_session_name(path)
  end
  return _name_cache
end

-- ============================================================
-- rofi selection — Lua-first: only os.execute for the GUI process
-- ============================================================

local function rofi_select(sessions)
  if #sessions == 0 then
    return nil
  end

  -- Build display-name → full-path mapping, disambiguating duplicates
  local mapping = {}
  local seen = {}
  local lines = {}

  for _, path in ipairs(sessions) do
    local name = resolve_session_name(path)
    local display = name
    if seen[display] then
      local i = 2
      while seen[display .. ' (' .. i .. ')'] do
        i = i + 1
      end
      display = display .. ' (' .. i .. ')'
    end
    seen[display] = true
    mapping[display] = path
    lines[#lines + 1] = display
  end

  local tmp_in = os.tmpname()
  local f = io.open(tmp_in, 'w')
  if not f then
    return nil
  end
  for _, line in ipairs(lines) do
    f:write(line .. '\n')
  end
  f:close()

  local tmp_out = os.tmpname()
  os.execute(
    'rofi -dmenu -p "Session: " -theme dmenu-custom < "'
    .. tmp_in .. '" > "' .. tmp_out .. '"'
  )

  local selected = nil
  local f2 = io.open(tmp_out, 'r')
  if f2 then
    local display = f2:read('*l')
    f2:close()
    if display and display ~= '' then
      display = display:match('^(.-)%s*$') or ''
      selected = mapping[display]
    end
  end

  os.remove(tmp_in)
  os.remove(tmp_out)

  return selected
end

-- Convenience: discover all sessions, let user pick one via rofi
local function pick_session()
  return rofi_select(find_sessions())
end

-- ============================================================
-- fzf selection
-- ============================================================

local function fzf_select(sessions)
  if #sessions == 0 then
    return nil
  end

  local tmp_in = os.tmpname()
  local f = io.open(tmp_in, 'w')
  if not f then
    return nil
  end
  for _, s in ipairs(sessions) do
    f:write(s .. '\n')
  end
  f:close()

  local tmp_out = os.tmpname()
  os.execute(
    'fzf-tmux -p --no-extended < "' .. tmp_in .. '" > "' .. tmp_out .. '"'
  )

  local selected = ''
  local f2 = io.open(tmp_out, 'r')
  if f2 then
    selected = f2:read('*a'):match('^(.-)%s*$') or ''
    f2:close()
  end

  os.remove(tmp_in)
  os.remove(tmp_out)

  if selected == '' then
    return nil
  end
  return selected
end

-- ============================================================
-- tmux helpers
-- ============================================================

local function tmux_is_inside()
  return os.getenv('TMUX') ~= nil
end

local function tmux_server_running()
  local p = io.popen('pgrep -x tmux', 'r')
  if not p then
    return false
  end
  local result = p:read('*a')
  p:close()
  return result ~= ''
end

local function tmux_has_session(name)
  local p = io.popen('tmux has-session -t="' .. name .. '" 2>/dev/null')
  if not p then
    return false
  end
  local _, exit_type, exit_code = p:close()
  return exit_type == 'exit' and exit_code == 0
end

local function tmux_new_session(name, cwd)
  os.execute('tmux new-session -ds "' .. name .. '" -c "' .. cwd .. '"')
end

local function tmux_switch_client(name)
  os.execute('tmux switch-client -t "' .. name .. '"')
end

-- ============================================================
-- Main entry point
-- ============================================================

local function run(selected)
  if not selected or selected == '' then
    local sessions = find_sessions()
    selected = fzf_select(sessions)
  end

  if not selected or selected == '' then
    return
  end

  local session_name = resolve_session_name(selected)

  if not tmux_is_inside() and not tmux_server_running() then
    os.execute('tmux new-session -s "' .. session_name .. '" -c "' .. selected .. '"')
    return
  end

  if not tmux_has_session(session_name) then
    tmux_new_session(session_name, selected)
  end

  tmux_switch_client(session_name)
end

-- ============================================================
-- Cache file export — writes the session path list so the shell
-- script can skip its own scan on subsequent invocations.
-- ============================================================

local function write_session_cache(path)
  path = path or CACHE_FILE
  local sessions = find_sessions()
  local f = io.open(path, 'w')
  if not f then
    return false
  end
  for _, s in ipairs(sessions) do
    f:write(s .. '\n')
  end
  f:close()
  return true
end

-- ============================================================
-- Module exports
-- ============================================================

return {
  find_sessions = find_sessions,
  resolve_session_name = resolve_session_name,
  fzf_select = fzf_select,
  rofi_select = rofi_select,
  pick_session = pick_session,
  run = run,
  write_session_cache = write_session_cache,
}
