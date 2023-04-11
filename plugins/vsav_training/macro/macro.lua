local input = require './vsav_training/utils/input-util'

-- local labels = {
--   P1 = 'P1:',
--   P2 = 'P2:',
-- }

local tokens = {
  UP      = 'U',
  DOWN    = 'D',
  LEFT    = 'L',
  RIGHT   = 'R',
  LP      = '1',
  MP      = '2',
  HP      = '3',
  LK      = '4',
  MK      = '5',
  HK      = '6',
  START   = 'S',
  COIN    = 'C',
  ADV_ONE = ',',
  WAIT_X  = 'W',
}

-- local modifiers = {
--   AUTOCORRECT_DIR = '*',
--   HOLD            = '_',
--   RELEASE         = '^',
-- }

---@type inputs
local p1_input_map = {}
---@type inputs
local p2_input_map = {}

-- can abstract this further for portability
do
  p1_input_map[tokens.UP]    = input.P1.UP
  p1_input_map[tokens.DOWN]  = input.P1.DOWN
  p1_input_map[tokens.LEFT]  = input.P1.LEFT
  p1_input_map[tokens.RIGHT] = input.P1.RIGHT
  p1_input_map[tokens.LP]    = input.P1.LP
  p1_input_map[tokens.MP]    = input.P1.MP
  p1_input_map[tokens.HP]    = input.P1.HP
  p1_input_map[tokens.LK]    = input.P1.LK
  p1_input_map[tokens.MK]    = input.P1.MK
  p1_input_map[tokens.HK]    = input.P1.HK
  p1_input_map[tokens.START] = input.P1.START -- TODO: P1 start isn't working for some reason
  p1_input_map[tokens.COIN]  = input.P1.COIN
  p2_input_map[tokens.UP]    = input.P2.UP
  p2_input_map[tokens.DOWN]  = input.P2.DOWN
  p2_input_map[tokens.LEFT]  = input.P2.LEFT
  p2_input_map[tokens.RIGHT] = input.P2.RIGHT
  p2_input_map[tokens.LP]    = input.P2.LP
  p2_input_map[tokens.MP]    = input.P2.MP
  p2_input_map[tokens.HP]    = input.P2.HP
  p2_input_map[tokens.LK]    = input.P2.LK
  p2_input_map[tokens.MK]    = input.P2.MK
  p2_input_map[tokens.HK]    = input.P2.HK
  p2_input_map[tokens.START] = input.P2.START
  p2_input_map[tokens.COIN]  = input.P2.COIN
end

local function get_macro_file(filename)
  local file = io.open(SCRIPT_SETTINGS.macro_dir .. filename, 'r')
  if not file then return nil end
  local p1 = file:read('l')
  local p2 = file:read('l')
  file:close()
  return p1, p2
end

local function parse_wait(macro_string, i)
  local wait = ''
  local j = i + 1
  local c = string.sub(macro_string, j, j)
  while string.match(c, '[0-9]') do
    c = string.sub(macro_string, j, j)
    if string.match(c, '[0-9]') then
      wait = wait .. c
      j = j + 1
    end
  end
  return { wait = tonumber(wait), i = j }
end

---@param token string
---@param input_map inputs
local function parse_token(token, input_map)
  return {
    input = input_map[token].field,
  }
end

local function parse_macro(macro_string)
  local macro_steps = {}
  local player = string.sub(macro_string, 1, 3)
  local input_map
  if player == 'P1:' then input_map = p1_input_map else input_map = p2_input_map end
  macro_string = string.sub(macro_string, 4) -- strip label
  local i = 1
  while i <= string.len(macro_string) do
    local c = string.sub(macro_string, i, i)
    if c == 'W' then
      local wait_obj = parse_wait(macro_string, i)
      i = wait_obj.i
      for _ = 1, wait_obj.wait do
        table.insert(macro_steps, { wait = 1 }) -- lol
      end
    elseif c == ',' then
      table.insert(macro_steps, { wait = 1 })
      i = i + 1
    else
      local steps = {}
      local j = i
      while string.match(c, '[UDLR123456SC]') and j <= string.len(macro_string) do
        local parsed_input = parse_token(c, input_map)
        table.insert(steps, { input = parsed_input.input })
        j = j + 1
        c = string.sub(macro_string, j, j)
      end
      i = j
      table.insert(macro_steps, steps)
    end
  end
  return macro_steps
end

local macros = {}
local active_inputs = {}
local step = 1
local running = false

local function activate_inputs()
  for _, inp in pairs(active_inputs) do
    if inp.field ~= nil then
      inp.field:set_value(1)
    end
  end
end

local function deactivate_inputs()
  for _, inp in pairs(active_inputs) do
    if inp.field ~= nil then
      inp.field:set_value(0)
    end
  end
end

local function execute_macro(p1, p2)
  deactivate_inputs()
  active_inputs = {}
  print(step, 'execute_macro')
  if p1[step] and not p1[step].wait then
    for _, entry in pairs(p1[step]) do
      active_inputs[#active_inputs + 1] = entry.input
    end
  end
  if p2[step] and not p2[step].wait then
    for _, entry in pairs(p2[step]) do
      active_inputs[#active_inputs + 1] = entry.input
    end
  end
  if step < #p1 or step < #p2 then
    step = step + 1
    return true
  else
    step = 1
    return false
  end
end

local function process_frame()
  if #macros > 1 then
    if not execute_macro(macros[1], macros[2]) then
      PRINT_TABLE(active_inputs)
      deactivate_inputs()
      macros = {}
      running = false
    else
      PRINT_TABLE(active_inputs)
      running = true
      activate_inputs()
    end
  end
end

local function load_macro(filename)
  if running then return end
  running = true
  filename = 'recording.vsr'
  local p1, p2 = get_macro_file(filename)
  local p1_inputs = nil
  local p2_inputs = nil
  p1_inputs = parse_macro(p1)
  if p1 == nil then
    print('no file!')
    running = false
    return
  end
  if p2 ~= nil then
    p2_inputs = parse_macro(p2)
  end
  table.insert(macros, p1_inputs)
  table.insert(macros, p2_inputs)
end

emu.register_frame(process_frame)

return {
  ['load_macro'] = load_macro,
}