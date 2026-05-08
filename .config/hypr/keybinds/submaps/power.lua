local r = require('keybinds.submaps.registry')

local SHUTDOWN_CONFIRM = [[
choice=$(printf '%s\n' no no yes | wofi --show dmenu --height=150 --width=10) || exit 0
[ "$choice" = "yes" ] && systemctl poweroff
]]

r.define('power', 'reset', function(bind)
  bind('Return', hl.dsp.exit(),                          { description = 'Exit Hyprland' })
  bind('r',      hl.dsp.exec_cmd('systemctl reboot'),    { description = 'Reboot' })
  bind('s',      hl.dsp.exec_cmd('systemctl suspend'),   { description = 'Suspend' })
  bind('l',      hl.dsp.exec_cmd('hyprlock'),            { description = 'Lock' })
  bind('p',      hl.dsp.exec_cmd(SHUTDOWN_CONFIRM),      { description = 'Shutdown' })
  bind('escape', hl.dsp.submap('reset'),                 { description = 'Cancel' })
  bind('catchall', hl.dsp.submap('reset'))
end)
