local r = require('keybinds.submaps.registry')

r.define('cursor', function(bind)
  bind('h', hl.dsp.exec_cmd('wlrctl pointer move -10 0'),  { repeating = true, description = 'Move cursor left' })
  bind('j', hl.dsp.exec_cmd('wlrctl pointer move 0 10'),   { repeating = true, description = 'Move cursor down' })
  bind('k', hl.dsp.exec_cmd('wlrctl pointer move 0 -10'),  { repeating = true, description = 'Move cursor up' })
  bind('l', hl.dsp.exec_cmd('wlrctl pointer move 10 0'),   { repeating = true, description = 'Move cursor right' })

  bind('s', hl.dsp.exec_cmd('wlrctl pointer click left'),  { description = 'Left click' })
  bind('d', hl.dsp.exec_cmd('wlrctl pointer click middle'),{ description = 'Middle click' })
  bind('f', hl.dsp.exec_cmd('wlrctl pointer click right'), { description = 'Right click' })

  bind('e', hl.dsp.exec_cmd('wlrctl pointer scroll 10 0'), { repeating = true, description = 'Scroll down' })
  bind('r', hl.dsp.exec_cmd('wlrctl pointer scroll -10 0'),{ repeating = true, description = 'Scroll up' })
  bind('t', hl.dsp.exec_cmd('wlrctl pointer scroll 0 -10'),{ repeating = true, description = 'Scroll left' })
  bind('g', hl.dsp.exec_cmd('wlrctl pointer scroll 0 10'), { repeating = true, description = 'Scroll right' })

  bind('escape', hl.dsp.submap('reset'), { description = 'Exit cursor mode' })
  bind('catchall', hl.dsp.submap('reset'))
end)
