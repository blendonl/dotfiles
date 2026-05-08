--- Registry of submap bindings (key + description) keyed by submap name.
--- Each submap file calls `define` which mirrors `hl.define_submap`'s signature
--- and exposes a `bind` that delegates to `hl.bind` while recording metadata.
local M = { submaps = {} }

--- Wrap a dispatcher so it resets the active submap after running. Use for
--- action binds inside a submap that has nested submap entries: Hyprland's
--- per-submap `reset` flag would also fire for those nested entries (because
--- all Lua binds share the `__lua` handler), so we opt in per-bind instead.
function M.leaf(dispatcher)
  return function()
    dispatcher()
    hl.dsp.submap('reset')()
  end
end

local function record(submap, keys, opts)
  table.insert(M.submaps[submap], {
    key = keys,
    desc = (opts and (opts.description or opts.desc)) or '',
  })
end

--- Define a submap and its bindings.
--- @param name string
--- @param mode_or_body string|fun(bind: fun(keys:string, dispatcher:function, opts?:HL.BindOptions): HL.Keybind)
--- @param body? fun(bind: fun(keys:string, dispatcher:function, opts?:HL.BindOptions): HL.Keybind)
function M.define(name, mode_or_body, body)
  local mode
  if type(mode_or_body) == 'function' then
    body = mode_or_body
  else
    mode = mode_or_body
  end

  M.submaps[name] = {}

  local bind = function(keys, dispatcher, opts)
    record(name, keys, opts)
    return hl.bind(keys, dispatcher, opts or {})
  end

  if mode then
    hl.define_submap(name, mode, function() body(bind) end)
  else
    hl.define_submap(name, function() body(bind) end)
  end
end

return M
