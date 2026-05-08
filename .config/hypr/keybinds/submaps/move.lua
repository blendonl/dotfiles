local r = require('keybinds.submaps.registry')
local workspaces = require('workspaces.registry')

local function shell_quote(s)
  return "'" .. s:gsub("'", [['\'']]) .. "'"
end

-- Builds a wofi pipeline that lets the user pick a workspace whose identifier
-- contains `filter`, then dispatches `dispatcher` against it. Stays as a shell
-- pipeline because wofi is interactive and Lua has no non-blocking way to wait
-- on its result.
local function pick_workspace_cmd(filter, dispatcher)
  local idents = {}
  for _, name in ipairs(workspaces.names()) do
    if name:find(filter, 1, true) then
      idents[#idents + 1] = name
    end
  end
  table.sort(idents)
  if #idents == 0 then return 'true' end

  local args = ''
  for _, n in ipairs(idents) do
    args = args .. ' ' .. shell_quote(n)
  end
  return string.format(
    [==[sel=$(printf '%%s\n'%s | wofi --show dmenu --sort-order=default) || exit 0
[ -n "$sel" ] && hyprctl dispatch %s "$sel"]==],
    args, dispatcher
  )
end

r.define('move', 'reset', function(bind)
  bind('w', hl.dsp.exec_cmd(pick_workspace_cmd('work', 'movetoworkspace')),
                                                  { description = 'Move to work workspace' })
  bind('p', hl.dsp.exec_cmd(pick_workspace_cmd('personal', 'movetoworkspace')),
                                                  { description = 'Move to personal workspace' })
  bind('escape', hl.dsp.submap('reset'),          { description = 'Cancel' })
  bind('catchall', hl.dsp.submap('reset'))
end)
