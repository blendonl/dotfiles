local r = require('keybinds.submaps.registry')

r.define('gaming', 'reset', function(bind)
  bind('s', hl.dsp.focus({ workspace = 'name:steam' }),   { description = 'Steam' })
  bind('k', hl.dsp.focus({ workspace = 'name:kovaaks' }), { description = 'Kovaaks' })
  bind('escape', hl.dsp.submap('reset'),                  { description = 'Cancel' })
  bind('catchall', hl.dsp.submap('reset'))
end)
