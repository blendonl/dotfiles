local r = require('keybinds.submaps.registry')
local workspaces = require('workspaces.registry')


r.define('go', 'reset', function(bind)
  bind("1", hl.dsp.focus({ workspace = "1", on_current_monitor = true, description = "Focus workspace 1" }))
  bind("2", hl.dsp.focus({ workspace = "2", on_current_monitor = true, description = "Focus workspace 2" }))
  bind("3", hl.dsp.focus({ workspace = "3", on_current_monitor = true, description = "Focus workspace 3" }))
  bind("4", hl.dsp.focus({ workspace = "4", on_current_monitor = true, description = "Focus workspace 4" }))
  bind("5", hl.dsp.focus({ workspace = "5", on_current_monitor = true, description = "Focus workspace 5" }))
  bind("t",
    hl.dsp.focus({
      workspace = "name:terminal-personl",
      on_current_monitor = true,
      description =
      "Focus workspace terminal"
    }))
  bind("b",
    hl.dsp.focus({ workspace = "name:browser-personl", on_current_monitor = true, description = "Focus workspace browser" }))
  bind("m",
    hl.dsp.focus({ workspace = "name:meeting-personl", on_current_monitor = true, description = "Focus workspace meeting" }))
  bind('catchall', hl.dsp.submap('reset'))
end)
