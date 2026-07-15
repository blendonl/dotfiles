-- Workspace definitions for per-session workspace rules.
-- Each entry defines a workspace suffix (term, browser, editor) and an
-- on_created_empty callback that returns the command Hyprland runs when
-- the workspace is first opened.
--
-- Remote sessions (paths under /mnt/data/) open SSH terminals into the
-- devserver's tmux session instead of creating local tmux sessions.

local STATE_FILE = os.getenv('HOME') .. '/.local/state/hypr/session.json'

local function is_remote(dir)
  return dir:sub(1, 9) == '/mnt/data'
end

-- Look up the remote_tmux_session field from session.json for a given
-- session name.  Returns nil for local sessions or if the field isn't
-- present (e.g. legacy session saved before this feature).
local function get_remote_tmux_session(name)
  local f = io.open(STATE_FILE, 'r')
  if not f then
    return nil
  end
  local raw = f:read('*a')
  f:close()

  -- Extract: "name":{"dir":"...","remote_tmux_session":"session~branch",...}
  local escaped = name:gsub('"', '\\"')
  local _, after = raw:find('"' .. escaped .. '"%s*:%s*{')
  if not after then
    return nil
  end
  -- Search for remote_tmux_session within this session's object.
  -- string.find returns (start, end, capture1, ...) — we need the third value.
  local _, _, session = raw:find('"remote_tmux_session"%s*:%s*"([^"]*)"', after)
  return session
end

-- Look up the browser_url field from session.json for a given session name.
-- The URL points to the KasmWeb browser container (ensure-compose).
-- Returns nil if not present (legacy sessions, or local sessions without compose).
local function get_browser_url(name)
  local f = io.open(STATE_FILE, 'r')
  if not f then
    return nil
  end
  local raw = f:read('*a')
  f:close()

  local escaped = name:gsub('"', '\\"')
  local _, after = raw:find('"' .. escaped .. '"%s*:%s*{')
  if not after then
    return nil
  end
  local _, _, url = raw:find('"browser_url"%s*:%s*"([^"]*)"', after)
  return url
end

-- Derive the project-specific tmux socket from the session name.
-- session-picker / project-picker use: ~/.tmux-socket-<project_name>
-- Session names are "<project_name>~<branch>".
local function get_tmux_sock(sess)
  local proj = sess:match('^([^~]+)~')
  if proj then
    return '~/.tmux-socket-' .. proj
  end
  return '~/.tmux-socket'
end

return {
  {
    suffix = 'term',
    default = true,
    on_created_empty = function(dir, name)
      if is_remote(dir) then
        local sess = get_remote_tmux_session(name) or name
        local sock = get_tmux_sock(sess)
        -- Try project-specific socket first, fall back to default (legacy sessions)
        return 'alacritty --command ssh -t devserver "tmux -S ' .. sock .. ' attach -t ' .. sess .. ' 2>/dev/null || tmux -S ~/.tmux-socket attach -t ' .. sess .. '"'
      end

      -- Local: create tmux session if needed, then attach
      os.execute('tmux has-session -t="' ..
        name .. '" 2>/dev/null || tmux new-session -ds "' .. name .. '" -c "' .. dir .. '"')
      return 'alacritty --command tmux attach -t ' .. name
    end,
  },
  {
    suffix = 'browser',
    on_created_empty = function(dir, name)
      local profile_dir = name:gsub('/', '-')

      -- Remote session: browser URL is stored in session.json by the
      -- shell picker after querying the server's macvlan IP allocation.
      if is_remote(dir) then
        local url = get_browser_url(name)
        if url then
          return 'chromium --app=' .. url
              .. ' --profile-directory="' .. profile_dir .. '"'
        end
        -- Legacy session (no browser_url saved yet): fall back to the
        -- server's hostname.  macvlan containers won't be reachable this
        -- way, but re-selecting the session in the picker will fix it.
        return 'chromium --app=https://devserver:6901'
            .. ' --profile-directory="' .. profile_dir .. '"'
      end

      -- Local session: check for a local compose setup (only meaningful
      -- on machines that have podman).
      local box_name = name:gsub('/', '-')
      local compose_file = '/tmp/compose/' .. box_name .. '/compose.yml'
      local compose_f = io.open(compose_file, 'r')
      if compose_f then
        compose_f:close()
        local url = 'https://localhost:6901'
        local ip_file = io.open('/tmp/compose/ip-allocations.txt', 'r')
        if ip_file then
          for line in ip_file:lines() do
            local alloc_box, ip = line:match('^(%S+)%s+(%S+)$')
            if alloc_box == box_name and ip then
              url = 'https://' .. ip .. ':6901'
              break
            end
          end
          ip_file:close()
        end
        return 'chromium --app=' .. url
            .. ' --profile-directory="' .. profile_dir .. '"'
      end

      -- No local compose.  This machine doesn't have podman, so browser
      -- containers live on the server — use its hostname as a best-effort
      -- default (macvlan IPs are preferred but not available without the
      -- shell picker's SSH query).
      return 'chromium --app=https://devserver:6901'
          .. ' --profile-directory="' .. profile_dir .. '"'
    end,
  },
  {
    suffix = 'editor',
    on_created_empty = function(dir, name)
      if is_remote(dir) then
        local sess = get_remote_tmux_session(name) or name
        local sock = get_tmux_sock(sess)
        return 'alacritty --command ssh -t devserver "tmux -S ' .. sock .. ' attach -t ' .. sess .. ' 2>/dev/null || tmux -S ~/.tmux-socket attach -t ' .. sess .. '"'
      end
      return 'neovide --working-directory ' .. dir
    end,
  },
}
