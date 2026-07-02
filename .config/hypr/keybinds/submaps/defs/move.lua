local r = require('keybinds.submaps.core.registry')
local workspaces = require('keybinds.submaps.workspaces.registry')
local state = require('session.state')

local function move_session(ws_type)
  return function()
    local ses = state.get_active_name()

    if not ses then
      return
    end

    hl.dispatch(hl.dsp.window.move({
      workspace = 'name:' .. ses .. '/' .. ws_type,
    }))

    state.set_last_workspace(ws_type)
  end
end


r.define('move', 'reset', function(bind)
  for _, value in pairs(workspaces) do
    bind(value.key, hl.dsp.window.move({ workspace = 'name:' .. value.spec.workspace }),
      { description = value.spec.description })
  end


  bind('t', move_session('term'), { description = 'Session terminal' })
  bind('b', move_session('browser'), { description = 'Session browser' })
  bind('e', move_session('editor'), { description = 'Session editor' })



  bind('escape', hl.dsp.submap('reset'), { description = 'Cancel' })
  bind('catchall', hl.dsp.submap('reset'))
end)
