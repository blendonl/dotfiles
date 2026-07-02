local picker = require('session.session_picker')
local state = require('session.state')
local default_ws = require('session.default_workspaces')

local M = {}

--- Register workspace rules for a session.
--- Called both at startup (for all saved sessions) and when activating
--- a new session at runtime.
--- @param name string  session name
--- @param dir  string  session directory
local function register_session_workspaces(name, dir)
  for _, ws_type in ipairs(default_ws) do
    local on_created = ws_type.on_created_empty(dir, name)
    hl.workspace_rule({
      workspace = 'name:' .. name .. '/' .. ws_type.suffix,
      on_created_empty = on_created,
      default = ws_type.default,
    })
  end
end

--- Activate a session given its filesystem path.
--- Registers workspace rules, persists state, and starts a detached tmux session.
--- Called at config load time (restore) — NOT from keybinds at runtime
--- because the blocking os.execute for tmux is fast enough at startup.
--- @param session_path string  full path to the project directory
--- @return boolean  true on success
function M.activate_session(session_path)
  if not session_path or session_path == '' then
    return false
  end

  local name = picker.resolve_session_name(session_path)

  -- Persist to JSON (preserves last_workspace when re-saving same session)
  state.save(name, session_path)

  -- Register workspace rules for this session
  register_session_workspaces(name, session_path)

  -- Restore the last-focused workspace if one was saved for this session.
  local last_ws = state.get_last_workspace()
  if last_ws then
    hl.dispatch(hl.dsp.focus({
      workspace = 'name:' .. name .. '/' .. last_ws,
    }))
  end

  return true
end

--- Restore all active sessions at startup.
--- Registers workspace rules for every saved session and focuses
--- the last active session's last-focused workspace.
function M.restore_last_session()
  local all = state.get_all()
  if not all or not next(all.sessions) then
    return
  end

  -- Register workspace rules for EVERY saved session so that
  -- per-session workspaces (term, browser, editor) survive restarts.
  for ses_name, ses in pairs(all.sessions) do
    register_session_workspaces(ses_name, ses.dir)
  end

  -- Focus the last active session's last workspace
  local saved = state.restore()
  if saved then
    local last_ws = state.get_last_workspace()
    if last_ws then
      hl.dispatch(hl.dsp.focus({
        workspace = 'name:' .. saved.name .. '/' .. last_ws,
      }))
    end
  end
end

M.restore_last_session()

return M
