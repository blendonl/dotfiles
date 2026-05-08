local r = require('keybinds.submaps.registry')

local function waydroid_resize()
  local w = hl.get_active_window()
  if not w or not w.size then return end
  local size = w.size
  local width = size[1] or size.x or size.width
  local height = size[2] or size.y or size.height
  if not width or not height then return end
  hl.dsp.exec_cmd(
    string.format('waydroid shell wm size %dx%d', math.floor(width), math.floor(height))
  )()
end

r.define('window', function(bind)
  bind('F', r.leaf(hl.dsp.window.fullscreen()), { description = 'Fullscreen' })
  bind('D', r.leaf(hl.dsp.window.fullscreen_state({ internal = 0, client = 1, action = 'toggle' })),
    { description = 'Fake fullscreen' })
  bind('C', r.leaf(hl.dsp.window.close()), { description = 'Close window' })
  bind('Space', r.leaf(hl.dsp.layout('togglesplit')), { description = 'Toggle split' })

  bind('P', hl.dsp.submap('reserved_space'), { description = 'Reserved space...' })
  bind('M', hl.dsp.submap('move'), { description = 'Move to workspace...' })
  bind('R', hl.dsp.submap('resize'), { description = 'Resize...' })

  bind('W', waydroid_resize, { description = 'Resize Waydroid' })

  bind('escape', hl.dsp.submap('reset'), { description = 'Cancel' })
  bind("catchall", hl.dsp.submap("reset"))
end)
