local r = require('keybinds.submaps.registry')

r.define('search', 'reset', function(bind)
  bind('a', hl.dsp.exec_cmd('sherlock'),
                                                  { description = 'App launcher' })
  bind('v', hl.dsp.exec_cmd('cliphist list | wofi -dmenu | cliphist decode | wl-copy'),
                                                  { description = 'Clipboard history' })
  bind('escape', hl.dsp.submap('reset'),          { description = 'Cancel' })
  bind('catchall', hl.dsp.submap('reset'))
end)
