local ioport = manager.machine.ioport

---@alias inputs table<string, { field: ioport_field | nil, default_name: string, is_pressed: (fun(): boolean) | nil }>
---@type inputs
local p1 = {
  UP    = { field = nil, default_name = 'P1 Up',          is_pressed = nil },
  DOWN  = { field = nil, default_name = 'P1 Down',        is_pressed = nil },
  LEFT  = { field = nil, default_name = 'P1 Left',        is_pressed = nil },
  RIGHT = { field = nil, default_name = 'P1 Right',       is_pressed = nil },
  LP    = { field = nil, default_name = 'P1 Button 1',    is_pressed = nil },
  MP    = { field = nil, default_name = 'P1 Button 2',    is_pressed = nil },
  HP    = { field = nil, default_name = 'P1 Button 3',    is_pressed = nil },
  LK    = { field = nil, default_name = 'P1 Button 4',    is_pressed = nil },
  MK    = { field = nil, default_name = 'P1 Button 5',    is_pressed = nil },
  HK    = { field = nil, default_name = 'P1 Button 6',    is_pressed = nil },
  START = { field = nil, default_name = '1 Player Start', is_pressed = nil },
  COIN  = { field = nil, default_name = 'Coin 1',         is_pressed = nil },
}

---@type inputs
local p2 = {
  UP    = { field = nil, default_name = 'P2 Up',           is_pressed = nil },
  DOWN  = { field = nil, default_name = 'P2 Down',         is_pressed = nil },
  LEFT  = { field = nil, default_name = 'P2 Left',         is_pressed = nil },
  RIGHT = { field = nil, default_name = 'P2 Right',        is_pressed = nil },
  LP    = { field = nil, default_name = 'P2 Button 1',     is_pressed = nil },
  MP    = { field = nil, default_name = 'P2 Button 2',     is_pressed = nil },
  HP    = { field = nil, default_name = 'P2 Button 3',     is_pressed = nil },
  LK    = { field = nil, default_name = 'P2 Button 4',     is_pressed = nil },
  MK    = { field = nil, default_name = 'P2 Button 5',     is_pressed = nil },
  HK    = { field = nil, default_name = 'P2 Button 6',     is_pressed = nil },
  START = { field = nil, default_name = '2 Players Start', is_pressed = nil },
  COIN  = { field = nil, default_name = 'Coin 2',          is_pressed = nil },
}

---@param f ioport_field
local function supported(f)
  if f.is_analog or f.is_toggle then
    return false
  elseif (f.type_class == 'config') or (f.type_class == 'dipswitch') then
    return false
  else
    return true
  end
end

---@return table<ioport_field>
local function get_input_fields()
  ---@type table<ioport_field>
  local fields = {}

  ---@param a ioport_field
  ---@param b ioport_field
  local function compare(a, b)
    if     a.device.tag < b.device.tag then return true
    elseif a.device.tag > b.device.tag then return false end
    local  group_a = ioport:type_group(a.type, a.player)
    local  group_b = ioport:type_group(b.type, b.player)
    if     group_a < group_b then return true
    elseif group_a > group_b then return false
    elseif a.type < b.type   then return true
    elseif a.type > b.type   then return false
    else                          return a.name < b.name end
  end
  for _, port in pairs(ioport.ports) do
    for _, field in pairs(port.fields) do
      if (not supported) or supported(field) then
        table.insert(fields, field)
      end
    end
  end
  table.sort(fields, compare)
  return fields
end

do
  local input_fields = get_input_fields()
  -- horribly inefficient, but runs once at startup
  for _, v in pairs(input_fields) do
    for i, w in pairs(p1) do
      if v.default_name == w.default_name then
        p1[i].field = v
        p1[i].is_pressed = function()
          local pressed = v.port:read() & v.mask == 0 -- active low
          return pressed
        end
      end
    end
    for i, w in pairs(p2) do
      if v.default_name == w.default_name then
        p2[i].field = v
        p2[i].is_pressed = function()
          local pressed = v.port:read() & v.mask == 0 -- active low
          return pressed
        end
      end
    end
  end
end

return {
  ['P1'] = p1,
  ['P2'] = p2,
  ---@return table<{ P1: inputs, P2: inputs }>
  ['get_currently_pressed'] = function()
    local filter = function(item)
      return item.is_pressed()
    end
    local pressed = { P1 = {}, P2 = {} }
    pressed.P1 = FILTER_TABLE_BY_VALUE(p1, filter)
    pressed.P2 = FILTER_TABLE_BY_VALUE(p2, filter)
    return pressed
  end,
  ['activate_inputs'] = function(inputs)
    for _, v in pairs(inputs) do
      p2[v].field:set_value(1)
    end
  end,
  ['deactivate_inputs'] = function(inputs)
    for _, v in pairs(inputs) do
      p2[v].field:set_value(0)
    end
  end,
}
