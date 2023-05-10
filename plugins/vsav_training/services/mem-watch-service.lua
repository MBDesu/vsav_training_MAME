---this script is meant to be a singleton; its single instance is instantiated
---in [`init.lua`](../init.lua)

local cpu = manager.machine.devices[':maincpu']
local program = cpu.spaces['program']

---@type table<string, passthrough_handler>
local passthrough_handlers = {}

local function watch_reads(name, start_addr, size, callback)
  local adjusted_size = size
  if size == BYTE then
    adjusted_size = 2
  end
  passthrough_handlers[name] = program:install_read_tap(start_addr, start_addr + adjusted_size - 1, name,
    function(offset, data, mask)
      if size == BYTE then
        data = (data & 0xFF00) >> 8
      end
      print(name)
      return callback(offset, data, mask)
    end)
  return passthrough_handlers[name]
end

local function watch_writes(name, start_addr, size, callback)
  local adjusted_size = size
  if size == BYTE then
    adjusted_size = 2
  end
  passthrough_handlers[name] = program:install_write_tap(start_addr, start_addr + adjusted_size - 1, name,
    function(offset, data, mask)
      if size == BYTE then
        if offset ~= start_addr then return end
        data = (data & 0xFF00) >> 8
      end
      print(name)
      return callback(offset, data, mask)
    end)
  return passthrough_handlers[name]
end

emu.register_frame(function()
  for _, passthrough_handler in pairs(passthrough_handlers) do
    passthrough_handler:reinstall()
  end
end)

return {
  ['watch_reads'] = watch_reads,
  ['watch_writes'] = watch_writes,
}