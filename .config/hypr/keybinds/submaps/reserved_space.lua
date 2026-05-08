local r = require('keybinds.submaps.registry')

local RES_PX = 600

local function add_reserved_space()
  local m = hl.get_active_monitor()
  if not m then return end

  local actual_width = m.width / m.scale
  local move         = math.floor(actual_width - RES_PX)
  local pct          = math.floor(RES_PX * 100 / actual_width)

  hl.notification.create({
    output = '',
    description = 'test',
  })

  hl.monitor({ output = m.name, reserved = { right = RES_PX } })

  hl.dsp.window.float({ action = 'on' })()
  hl.dsp.window.move({ position = move .. ' 0', exact = true })()
  hl.dsp.window.resize({ size = pct .. '% 100%', exact = true })()
  hl.dsp.window.pin()()
end

local function remove_reserved_space()
  local m = hl.get_active_monitor()
  if not m then return end
  hl.monitor({ output = m.name, reserved = 0 })
  hl.dsp.focus({ window = 'floating' })()
  hl.dsp.window.float({ action = 'off' })()
end

r.define('reserved_space', 'reset', function(bind)
  bind('p', add_reserved_space, { description = 'Pin window to right side' })
  bind('u', remove_reserved_space, { description = 'Unpin and clear reserved space' })
  bind('escape', hl.dsp.submap('reset'), { description = 'Cancel' })
  bind('catchall', hl.dsp.submap('reset'))
end)

return {
  add = add_reserved_space,
  remove = remove_reserved_space,
}
