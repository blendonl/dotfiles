local r = require('keybinds.submaps.registry')

r.define('record', 'reset', function(bind)
  bind('v', hl.dsp.exec_cmd('hyprshot -m region --clipboard-only'),
                                                  { description = 'Region to clipboard' })
  bind('s', hl.dsp.exec_cmd('hyprshot -m region'), { description = 'Region screenshot' })
  bind('p', hl.dsp.exec_cmd('hyprpicker -a'),     { description = 'Pick color' })
  bind('escape', hl.dsp.submap('reset'),          { description = 'Cancel' })
  bind('catchall', hl.dsp.submap('reset'))
end)
