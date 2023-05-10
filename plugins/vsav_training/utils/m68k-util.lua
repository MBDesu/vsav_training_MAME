local m68k = require './vsav_training/constants/m68k'
local m = require './vsav_training/utils/memory-util'
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
  print(string.format('\27[33m%s\27[0m:    %08x', m68k.aux.CURPC,    get_reg(m68k.aux.CURPC)))
  print(string.format('\27[33m%s\27[0m:      %08x', m68k.aux.rPC,      get_reg(m68k.aux.rPC)))
  print(string.format('\27[33m%s\27[0m:       %08x', m68k.reg.IR,       get_reg(m68k.reg.IR)))
  print(string.format('\27[33m%s\27[0m: %08x', m68k.aux.CURFLAGS, get_reg(m68k.aux.CURFLAGS)))
  print(string.format('\27[33m%s\27[0m:       %08x', m68k.reg.SR,       get_reg(m68k.reg.SR)))
  print(string.format('\27[34m%s\27[0m: %08x\t\27[34m%s\27[0m: %08x\t\27[34m%s\27[0m: %08x\t\27[34m%s\27[0m:  %08x',
                                                                                m68k.reg.D0,  get_reg(m68k.reg.D0),
                                                                                m68k.reg.D1,  get_reg(m68k.reg.D1),
                                                                                m68k.reg.D2,  get_reg(m68k.reg.D2),
                                                                                m68k.reg.D3,  get_reg(m68k.reg.D3)))
  print(string.format('\27[34m%s\27[0m: %08x\t\27[34m%s\27[0m: %08x\t\27[34m%s\27[0m: %08x\t\27[34m%s\27[0m:  %08x',
                                                                                m68k.reg.D4, get_reg(m68k.reg.D4),
                                                                                m68k.reg.D5, get_reg(m68k.reg.D5),
                                                                                m68k.reg.D6, get_reg(m68k.reg.D6),
                                                                                m68k.reg.D7, get_reg(m68k.reg.D7)))
  print(string.format('\27[32m%s\27[0m: %08x\t\27[32m%s\27[0m: %08x\t\27[32m%s\27[0m: %08x\t\27[32m%s\27[0m:  %08x',
                                                                                m68k.reg.A0, get_reg(m68k.reg.A0),
                                                                                m68k.reg.A1, get_reg(m68k.reg.A1),
                                                                                m68k.reg.A2, get_reg(m68k.reg.A2),
                                                                                m68k.reg.A3, get_reg(m68k.reg.A3)))
  print(string.format('\27[32m%s\27[0m: %08x\t\27[32m%s\27[0m: %08x\t\27[32m%s\27[0m: %08x\t\27[32m%s\27[0m: %08x',
                                                                                m68k.reg.A4,  get_reg(m68k.reg.A4),
                                                                                m68k.reg.A5,  get_reg(m68k.reg.A5),
                                                                                m68k.reg.A6,  get_reg(m68k.reg.A6),
                                                                                m68k.ptr.USP, get_reg(m68k.ptr.USP)))
  print(string.format('\27[33m%s\27[0m: %08x', m68k.ptr.SP, get_reg(m68k.ptr.SP)))
end

local function print_stack_trace()
  local current_address = get_reg(m68k.ptr.USP)
  local stack_value = m.rdu(current_address)
  print(string.format(' \27[31mCURPC\27[0m: %06x', get_reg(m68k.reg.PC)))
  while stack_value ~= 0 do
    print(string.format('\27[31m%06x\27[0m: %06x', current_address, stack_value))
    current_address = current_address + 4
    stack_value = m.rdu(current_address)
  end
end

return {
  ['cpu'] = cpu,
  ['debug'] = debug,
  ['program_space'] = program_space,
  ['get_reg'] = get_reg,
  ['set_reg'] = set_reg,
  ['is_flag_set'] = is_flag_set,
  ['print_state'] = print_state,
  ['print_stack_trace'] = print_stack_trace,
}