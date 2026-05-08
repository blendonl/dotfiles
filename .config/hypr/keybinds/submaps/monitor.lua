local r = require('keybinds.submaps.registry')

r.define('monitor', 'reset', function(bind)
  bind('F', hl.dsp.focus({ monitor = '+1' }), { description = 'Focus next monitor' })
  bind('M', hl.dsp.workspace.move({ monitor = '+1' }), { description = 'Move workspace to next monitor' })
  bind('escape', hl.dsp.submap('reset'), { description = 'Cancel' })
  bind('catchall', hl.dsp.submap('reset'))
end)
