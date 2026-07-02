local r = require('keybinds.submaps.core.registry')

r.define("tasks", function(bind)
  hl.bind("catchall", hl.dsp.submap('reset'))
  hl.bind("escape", hl.dsp.submap('reset'))

  bind('n', hl.dsp.exec_cmd('qs ipc call task-create open'), { description = 'New Task' })
  bind('a', hl.dsp.exec_cmd('qs ipc call agenda open'), { description = 'New Task' })
  bind('l', hl.dsp.exec_cmd('qs ipc call task-list open'), { description = 'Task List' })
  bind('s', hl.dsp.exec_cmd('qs ipc call planner open'), { description = 'Task List' })
end)
