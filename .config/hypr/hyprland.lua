require('config')
require('keybinds')

local workspaces = require("keybinds.submaps.workspaces.registry")
for _, value in ipairs(workspaces) do
  hl.workspace_rule({
    workspace = value.spec.workspace,
    on_created_empty = value.spec.on_created_empty,
    default = value.spec.default,
  })
end
