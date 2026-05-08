local r = require('keybinds.submaps.registry')

r.define('normal', function(bind)
  bind('return', hl.dsp.exec_cmd('alacritty'), { description = 'Terminal' })

  bind('m', hl.dsp.submap('monitor'), { description = 'Monitor...' })
  bind('s', hl.dsp.submap('search'), { description = 'Search...' })
  bind('c', hl.dsp.submap('mouse'), { description = 'Cursor...' })
  bind('n', hl.dsp.submap('notes'), { description = 'Notes...' })
  bind('i', hl.dsp.submap('notification'), { description = 'Notifications...' })
  bind('p', hl.dsp.submap('power'), { description = 'Power...' })
  bind('r', hl.dsp.submap('record'), { description = 'Record...' })
  bind('g', hl.dsp.submap('go'), { description = 'Go to workspace...' })
  bind('w', hl.dsp.submap('window'), { description = 'Window...' })

  bind('TAB', hl.dsp.workspace.move({ monitor = '+1' }), { description = 'Move workspace to next monitor' })
  bind('SPACE', r.leaf(hl.dsp.focus({ workspace = "previous_per_monitor" })))


  bind('escape', hl.dsp.submap('reset'), { description = 'Cancel' })
  bind('catchall', hl.dsp.submap('reset'))
end)
