hl.define_submap('record', function()
  local r = require('keybinds.submaps.core.registry')
  hl.bind('catchall', hl.dsp.submap('reset'), { description = 'Cancel' })
  hl.bind('c', hl.dsp.exec_cmd('clipssh notpc@devserver &> /home/notpc/.config/hypr/test.ct'),
    { description = 'copy ssh' })


  hl.bind('v', hl.dsp.exec_cmd('hyprshot -m region --clipboard-only && clipssh notpc@devserver'))
  hl.bind('s', function()
    hl.dispatch(hl.dsp.exec_cmd('hyprshot -m region --clipboard-only'))
  end
  , { description = 'Region screenshot' })

  hl.bind('p', hl.dsp.exec_cmd('hyprpicker -a'), { description = 'Pick color' })

  hl.bind('escape', hl.dsp.submap('reset'), { description = 'Cancel' })
end)
