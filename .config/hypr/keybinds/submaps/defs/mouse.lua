local r = require('keybinds.submaps.core.registry')

r.define('mouse', function(bind)
  bind('mouse:272', hl.dsp.window.drag(), { mouse = true, description = 'Drag to move' })
  bind('mouse:273', hl.dsp.window.resize(), { mouse = true, description = 'Drag to resize' })
  bind('Z', hl.dsp.window.drag(), { mouse = true, description = 'Drag to move' })
  bind('SUPER + SUPER_L', hl.dsp.submap('reset'), { release = true, description = 'Exit cursor mode' })
end)
