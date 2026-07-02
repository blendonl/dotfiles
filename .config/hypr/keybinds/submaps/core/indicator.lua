local registry = require('keybinds.submaps.core.registry')

local function json_string(s)
  s = s:gsub('\\', '\\\\')
  s = s:gsub('"', '\\"')
  s = s:gsub('\n', '\\n')
  s = s:gsub('\r', '\\r')
  s = s:gsub('\t', '\\t')
  return '"' .. s .. '"'
end


local function encode_binds(binds)
  local parts = {}
  for _, b in ipairs(binds) do
    parts[#parts + 1] = '{"key":' .. json_string(b.key) .. ',"value":' .. json_string(b.desc) .. '}'
  end
  return '[' .. table.concat(parts, ',') .. ']'
end

local PAYLOAD_PATH = '/tmp/hl-indicator-payload.json'

local function write_payload(text)
  local f = io.open(PAYLOAD_PATH, 'w')
  if not f then return false end
  f:write(text)
  f:close()
  return true
end

hl.on("keybinds.submap", function(name)
  if not name or name == "" or name == "reset" then
    hl.dispatch(hl.dsp.exec_cmd("qs ipc call indicator hide"))
    return
  end

  local binds = registry.submaps[name] or {}
  if not write_payload(encode_binds(binds)) then return end

  hl.dispatch(hl.dsp.exec_cmd("qs ipc call indicator open " .. name .. " " .. PAYLOAD_PATH))
end)
