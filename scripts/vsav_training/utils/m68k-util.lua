local m68k = require './scripts/vsav_training/constants/m68k'
local cpu = manager.machine.devices[':maincpu']
local debug = cpu.debug
local program_space = cpu.spaces['program']

local get_reg = function(register)
  return cpu.state[register].value
end

local set_reg = function(register, value)
  cpu.state[register].value = value
end

local function get_ccr_mask(flag)
  if     flag == m68k.ccr_flag.C then return m68k.ccr_mask.C
  elseif flag == m68k.ccr_flag.V then return m68k.ccr_mask.V
  elseif flag == m68k.ccr_flag.Z then return m68k.ccr_mask.Z
  elseif flag == m68k.ccr_flag.N then return m68k.ccr_mask.N
  elseif flag == m68k.ccr_flag.X then return m68k.ccr_mask.X
  else                                return nil
  end
end

local is_flag_set = function(flag)
  local sr = cpu.state[m68k.reg.SR].value
  local ccr_mask = get_ccr_mask(flag)
  if ccr_mask ~= nil then
    return sr & ccr_mask >= ccr_mask
  end
  return false
end

local function print_state()
  for k, v in pairs(cpu.state) do
    print(k .. ': ' .. string.format('%x', v.value))
  end
end

return {
  ['cpu'] = cpu,
  ['debug'] = debug,
  ['program_space'] = program_space,
  ['get_reg'] = get_reg,
  ['set_reg'] = set_reg,
  ['is_flag_set'] = is_flag_set,
  ['print_state'] = print_state
}