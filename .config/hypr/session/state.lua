--- Session state backed by a persistent JSON file.
--- Stores all active sessions (not just one), each with its last workspace.
--- The shell-based session picker also writes this file, so all reads go
--- through the file — no in-memory cache that could become stale.
local M = {}

local PERSIST_DIR = os.getenv('HOME') .. '/.local/state/hypr'
local PERSIST_FILE = PERSIST_DIR .. '/session.json'

-- ============================================================
-- Minimal JSON helpers for the session.json structure.
-- Avoids external dependencies; handles only the constrained
-- shape we control: strings, objects with string values, no
-- arrays, no numbers, no booleans, no nulls.
-- ============================================================

local function json_escape(s)
  return s:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t')
end

local function json_unescape(s)
  -- Process \\ first (use placeholder), then others, then restore
  s = s:gsub('\\\\', '\x00')
  s = s:gsub('\\"', '"'):gsub('\\n', '\n'):gsub('\\r', '\r'):gsub('\\t', '\t')
  return s:gsub('\x00', '\\')
end

--- Encode the full state table to a JSON string.
--- @param data table  {sessions = {[name] = {dir, last_workspace?}}, last_active?}
local function encode(data)
  local p = {}
  p[#p + 1] = '{"sessions":{'
  local first = true
  for name, ses in pairs(data.sessions) do
    if not first then p[#p + 1] = ',' end
    first = false
    p[#p + 1] = '"' .. json_escape(name) .. '":{"dir":"' .. json_escape(ses.dir) .. '"'
    if ses.last_workspace then
      p[#p + 1] = ',"last_workspace":"' .. json_escape(ses.last_workspace) .. '"'
    end
    p[#p + 1] = '}'
  end
  p[#p + 1] = '}'
  if data.last_active then
    p[#p + 1] = ',"last_active":"' .. json_escape(data.last_active) .. '"'
  end
  return table.concat(p) .. '}'
end

--- Extract a JSON-encoded string starting at the opening quote.
--- Walks the string handling \" and \\ escapes, returns the position
--- after the closing quote and the unescaped content.
--- @param s    string  the raw JSON
--- @param pos  number  position of the opening '"'
--- @return number|nil  position after closing '"'
--- @return string|nil  unescaped content
local function extract_json_string(s, pos)
  if not pos then return nil end
  local start = s:find('"', pos)
  if not start then return nil end
  local i = start + 1
  while i <= #s do
    local c = s:sub(i, i)
    if c == '\\' then
      i = i + 2  -- skip escaped character
    elseif c == '"' then
      return i + 1, json_unescape(s:sub(start + 1, i - 1))
    else
      i = i + 1
    end
  end
  return nil  -- unterminated string
end

--- Find a JSON key and extract its string value.
--- E.g. given '"dir":"/path"', extracts '/path'.
--- @param s    string  the raw JSON
--- @param key  string  literal key name (no escapes needed)
--- @param pos  number  position to start searching from
--- @return number|nil  position after the value's closing '"'
--- @return string|nil  unescaped value
local function find_string_value(s, key, pos)
  local pattern = '"' .. key .. '":%s*"'
  local _, after = s:find(pattern, pos or 1)
  if not after then return nil end
  return extract_json_string(s, after)
end

--- Decode the JSON string back to a state table.
--- Handles both the new multi-session format and the legacy
--- single-session format (auto-migrates on next write).
--- @return table  {sessions = {[name] = {dir, last_workspace?}}, last_active?}
local function decode(raw)
  if not raw or raw == '' then
    return { sessions = {} }
  end

  -- Detect legacy single-session format: {"name":"...","dir":"..."}
  if raw:match('^%s*{"name":') then
    local _, name = find_string_value(raw, 'name', 1)
    local _, dir = find_string_value(raw, 'dir', 1)
    local _, last_ws = find_string_value(raw, 'last_workspace', 1)
    if name and dir then
      return {
        sessions = {
          [name] = {
            dir = dir,
            last_workspace = last_ws or nil,
          }
        },
        last_active = name,
      }
    end
    return { sessions = {} }
  end

  local data = { sessions = {} }

  -- Extract last_active
  local _, last_active = find_string_value(raw, 'last_active', 1)
  if last_active then
    data.last_active = last_active
  end

  -- Extract the sessions object block (between "sessions":{ and its matching })
  local ses_start, ses_brace = raw:find('"sessions":%s*{')
  if not ses_start then
    return data
  end

  -- Find matching closing brace for the sessions object
  local depth = 0
  local ses_end = nil
  for i = ses_brace, #raw do
    local c = raw:sub(i, i)
    if c == '{' then
      depth = depth + 1
    elseif c == '}' then
      depth = depth - 1
      if depth == 0 then
        ses_end = i
        break
      end
    end
  end

  if not ses_end then
    return data
  end

  local sessions_block = raw:sub(ses_brace + 1, ses_end - 1)
  if sessions_block:match('^%s*$') then
    return data -- empty sessions object
  end

  -- Parse each "name":{...} entry within the sessions block
  local pos = 1
  while pos <= #sessions_block do
    -- Extract the session name (JSON string key)
    local after_key, name = extract_json_string(sessions_block, pos)
    if not after_key or not name then break end

    -- Expect ":{" after the key
    local _, brace_pos = sessions_block:find('%s*:%s*{', after_key)
    if not brace_pos then break end

    -- Find matching closing brace for this session object
    local inner_depth = 0
    local inner_end = nil
    for i = brace_pos, #sessions_block do
      local c = sessions_block:sub(i, i)
      if c == '{' then
        inner_depth = inner_depth + 1
      elseif c == '}' then
        inner_depth = inner_depth - 1
        if inner_depth == 0 then
          inner_end = i
          break
        end
      end
    end

    if not inner_end then break end

    local ses_raw = sessions_block:sub(brace_pos, inner_end)
    local _, dir = find_string_value(ses_raw, 'dir', 1)
    local _, last_ws = find_string_value(ses_raw, 'last_workspace', 1)

    if dir and name then
      data.sessions[name] = {
        dir = dir,
        last_workspace = last_ws or nil,
      }
    end

    pos = inner_end + 1
    -- Skip trailing comma / whitespace
    while pos <= #sessions_block do
      local c = sessions_block:sub(pos, pos)
      if c == ',' or c == ' ' or c == '\n' or c == '\r' or c == '\t' then
        pos = pos + 1
      else
        break
      end
    end
  end

  return data
end

-- ============================================================
-- File I/O
-- ============================================================

--- Read and parse the state file. Returns the full state table.
local function read_file()
  local f = io.open(PERSIST_FILE, 'r')
  if not f then return { sessions = {} } end

  local raw = f:read('*a')
  f:close()

  return decode(raw)
end

--- Write the state table to the JSON file.
local function write_file(data)
  os.execute('mkdir -p "' .. PERSIST_DIR .. '"')
  local f = io.open(PERSIST_FILE, 'w')
  if f then
    f:write(encode(data) .. '\n')
    f:close()
  end
end

-- ============================================================
-- Public API
-- ============================================================

--- Return the full state table (all sessions + last_active).
--- @return table  {sessions = {...}, last_active = string|nil}
function M.get_all()
  return read_file()
end

--- Save (or update) a session. Sets it as last_active.
--- Preserves the existing last_workspace when re-saving the same
--- session (e.g. shell picker re-selecting the current session).
--- @param name string  sanitized session name (e.g. "dotfiles/hypr")
--- @param dir  string  full filesystem path
function M.save(name, dir)
  local data = read_file()

  -- Preserve last_workspace if this session already exists
  local existing_last_ws = nil
  if data.sessions[name] then
    existing_last_ws = data.sessions[name].last_workspace
  end

  data.sessions[name] = { dir = dir, last_workspace = existing_last_ws }
  data.last_active = name

  write_file(data)
end

--- Restore the last active session. Returns {name, dir} or nil.
--- Validates that the saved directory still exists on disk.
function M.restore()
  local data = read_file()
  if not data.last_active then return nil end

  local ses = data.sessions[data.last_active]
  if not ses then return nil end

  -- Verify the directory still exists
  local p = io.popen('test -d "' .. ses.dir .. '" && echo yes')
  if not p then return nil end
  local exists = p:read('*l')
  p:close()

  if exists ~= 'yes' then
    -- Stale session — remove it and try the next one, or clear
    data.sessions[data.last_active] = nil
    -- Pick another session as last_active if available
    local next_name = next(data.sessions)
    if next_name then
      data.last_active = next_name
      write_file(data)
      return { name = next_name, dir = data.sessions[next_name].dir }
    else
      M.clear()
      return nil
    end
  end

  return { name = data.last_active, dir = ses.dir }
end

--- Return the current active session name (or nil).
function M.get_active_name()
  local data = read_file()
  return data.last_active
end

--- Return the current active session directory (or nil).
function M.get_active_dir()
  local data = read_file()
  if not data.last_active then return nil end
  local ses = data.sessions[data.last_active]
  return ses and ses.dir or nil
end

--- Record the last-focused workspace type for the active session.
--- @param ws_type string  workspace suffix (e.g. "term", "browser", "editor")
function M.set_last_workspace(ws_type)
  local data = read_file()
  if not data.last_active then return end

  local ses = data.sessions[data.last_active]
  if ses then
    ses.last_workspace = ws_type
    write_file(data)
  end
end

--- Return the last-focused workspace type for the active session, or nil.
--- @return string|nil
function M.get_last_workspace()
  local data = read_file()
  if not data.last_active then return nil end
  local ses = data.sessions[data.last_active]
  return ses and ses.last_workspace or nil
end

--- Remove a session from the state.
--- If it was last_active, picks another session or clears last_active.
--- @param name string  session name to remove
function M.remove(name)
  local data = read_file()
  data.sessions[name] = nil
  if data.last_active == name then
    data.last_active = next(data.sessions)
  end
  write_file(data)
end

--- Clear all persistent state.
function M.clear()
  os.remove(PERSIST_FILE)
end

return M
