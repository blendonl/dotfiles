local r = require('keybinds.submaps.core.registry')
hl.define_submap('record', function()
  hl.bind('catchall', hl.dsp.submap('reset'), { description = 'Cancel' })

  hl.bind('v', hl.dsp.exec_cmd('hyprshot -m region --clipboard-only'))
  hl.bind('s', hl.dsp.exec_cmd('hyprshot -m region'), { description = 'Region screenshot' })
  hl.bind('p', hl.dsp.exec_cmd('hyprpicker -a'), { description = 'Pick color' })

  hl.bind('escape', hl.dsp.submap('reset'), { description = 'Cancel' })
end)
