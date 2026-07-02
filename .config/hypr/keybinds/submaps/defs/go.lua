local r = require('keybinds.submaps.core.registry')
local state = require('session.state')
local workspaces = require('keybinds.submaps.workspaces.registry')

local SCRIPT = os.getenv('HOME') .. '/.config/hypr/scripts/session-picker.sh'


local function go_session(ws_type)
  return function()
    local ses = state.get_active_name()

    if not ses then
      return
    end

    hl.dispatch(hl.dsp.focus({
      workspace = 'name:' .. ses .. '/' .. ws_type,
    }))

    state.set_last_workspace(ws_type)
  end
end

local function pick_session_async()
  hl.dispatch(hl.dsp.submap('reset'))
  hl.dispatch(hl.dsp.exec_cmd(SCRIPT))
end

r.define('go', function(bind)
  for _, value in pairs(workspaces) do
    bind(value.key, hl.dsp.focus({ workspace = value.spec.workspace }),
      { description = value.description })
  end


  bind('t', go_session('term'), { description = 'Session terminal' })
  bind('b', go_session('browser'), { description = 'Session browser' })
  bind('e', go_session('editor'), { description = 'Session editor' })


  bind('s', pick_session_async, { description = 'Switch session' })

  hl.bind('escape', hl.dsp.submap('reset'), { description = 'Cancel' })
  hl.bind('catchall', hl.dsp.submap('reset'))
end)
