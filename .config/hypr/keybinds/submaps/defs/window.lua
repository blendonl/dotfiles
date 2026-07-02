local r = require('keybinds.submaps.core.registry')



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



hl.define_submap('window', function()
  hl.bind("catchall", hl.dsp.submap("reset"))

  hl.bind('F', hl.dsp.window.fullscreen_state({ internal = 1, client = -1, action = 'toggle' }),
    { description = 'Fullscreen' })
  hl.bind('D', hl.dsp.window.fullscreen_state({ internal = 0, client = 1, action = 'toggle' }),
    { description = 'Fake fullscreen' })
  hl.bind('C', r.leaf(hl.dsp.window.close()), { description = 'Close window' })
  hl.bind('Space', r.leaf(hl.dsp.layout('togglesplit')), { description = 'Toggle split' })

  hl.bind('P', hl.dsp.submap('reserved_space'), { description = 'Reserved space...' })
  hl.bind('M', hl.dsp.submap('move'), { description = 'Move to workspace...' })
  hl.bind('R', hl.dsp.submap('resize'), { description = 'Resize...' })
  hl.bind('T', function()
    local monitor = hl.get_active_monitor()


    if monitor == nil then
      return
    end


    if monitor.reserved == { top = 0, bottom = 0, left = 0, rigt = 0 } or monitor.reserved == 0 or monitor.reserved == nil then
      hl.monitor({ output = monitor.name, reserved_area = { top = 0, bottom = 0, left = 0, right = 500 } })
    else
      hl.monitor({ output = monitor.name, reserved_area = { top = 0, bottom = 0, left = 0, right = 0 } })
    end


    hl.dispatch(hl.dsp.window.float({ action = 'toggle' }))
    hl.dispatch(hl.dsp.window.pin({ action = 'toggle' }))
    hl.dispatch(hl.dsp.window.fullscreen_state({ internal = 0, client = 1, action = 'toggle' }))
    hl.dispatch(hl.dsp.window.resize({ x = 500, y = 400 }))
    hl.dispatch(hl.dsp.window.move({ x = (monitor.width / monitor.scale) - 500, y = 0 }))
  end, { description = "Floating top right" })

  hl.bind('W', waydroid_resize, { description = 'Resize Waydroid' })

  hl.bind('escape', hl.dsp.submap('reset'), { description = 'Cancel' })
end)
