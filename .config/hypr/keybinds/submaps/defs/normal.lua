local r = require('keybinds.submaps.core.registry')

r.define("normal", function(bind)
  hl.bind("catchall", hl.dsp.submap('reset'))

  bind('r', hl.dsp.submap('record'), { description = 'Record' })
  require('keybinds.submaps.defs.record')


  bind('w', hl.dsp.submap('window', { description = 'Window' }))
  require('keybinds.submaps.defs.window')

  bind('a', hl.dsp.submap('monitor'), { description = 'Monitor' })
  require('keybinds.submaps.defs.monitor')

  bind('m', hl.dsp.submap('move'), { description = 'Move' })
  require('keybinds.submaps.defs.move')

  bind('t', hl.dsp.submap('tasks'), { description = 'Tasks' })
  require('keybinds.submaps.defs.tasks')

  bind('n', hl.dsp.submap('notes'), { description = 'Notes' })
  require('keybinds.submaps.defs.notes')

  bind('i', hl.dsp.submap('notification'), { description = 'Notification' })
  require('keybinds.submaps.defs.notification')

  bind('p', hl.dsp.submap('power'), { description = 'Power' })
  require('keybinds.submaps.defs.power')

  bind('s', hl.dsp.submap('search'), { description = 'Search' })
  require('keybinds.submaps.defs.search')

  bind('g', hl.dsp.submap('go'), { description = 'Go' })
  require('keybinds.submaps.defs.go')



  hl.bind('escape', hl.dsp.submap('reset'), { description = 'Cancel' })
end)
