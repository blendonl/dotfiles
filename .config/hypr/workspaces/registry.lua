--- Tracks every workspace registered through `rule(spec)` so other modules
--- (workspace pickers, indicators) can query the canonical list.
local M = { defs = {} }

function M.rule(spec)
  table.insert(M.defs, spec)
  hl.workspace_rule(spec)
end

--- Returns workspace identifiers in declaration order (e.g. "name:foo", "special:bar").
function M.names()
  local out = {}
  for _, d in ipairs(M.defs) do
    if d.workspace then
      out[#out + 1] = d.workspace
    end
  end
  return out
end

return M
