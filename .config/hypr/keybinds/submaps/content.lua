local r = require('keybinds.submaps.registry')

r.define('content', 'reset', function(bind)
  bind('y', hl.dsp.focus({ workspace = 'name:youtube' }), { description = 'YouTube' })
  bind('m', hl.dsp.focus({ workspace = 'name:music' }),   { description = 'Music' })
  bind('escape', hl.dsp.submap('reset'),                  { description = 'Cancel' })
  bind('catchall', hl.dsp.submap('reset'))
end)
