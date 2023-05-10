-- fair warning, this is a state management mess
-- FIXME: this shit broke; namely, the language needs redesigned or checking
-- for the case where an input is followed by a single comma being interpreted
-- as <input> -> wait two frames needs to be fixed
-- really, I think just writing the logic for holds would fix the whole thing
-- TODO: see how MAME's inputmacro fares by comparison. Might be better to just
-- use that.
local input = require './vsav_training/utils/input-util'
local image_util = require './vsav_training/utils/image-util'

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

local play_icon_texture = manager.machine.render:texture_alloc(
  image_util.argb32_bitmap_from_square_rgba32_bitmap_data(SCRIPT_SETTINGS.image_dir .. 'play.data')
)

local record_icon_texture = manager.machine.render:texture_alloc(
  image_util.argb32_bitmap_from_square_rgba32_bitmap_data(SCRIPT_SETTINGS.image_dir .. 'record.data')
)

---@type inputs
local p1_input_map = {}
---@type inputs
local p2_input_map = {}
---@type table<ioport_field>
local active_inputs = {}
local token_input_map = {}
local macros = {}
local macro_recording = {}

local step = 1
local is_executing_macro = false
local is_recording_macro = false

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
  p1_input_map[tokens.START] = input.P1.START
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

  token_input_map[input.P1.UP.default_name]    = tokens.UP
  token_input_map[input.P1.DOWN.default_name]  = tokens.DOWN
  token_input_map[input.P1.LEFT.default_name]  = tokens.LEFT
  token_input_map[input.P1.RIGHT.default_name] = tokens.RIGHT
  token_input_map[input.P1.LP.default_name]    = tokens.LP
  token_input_map[input.P1.MP.default_name]    = tokens.MP
  token_input_map[input.P1.HP.default_name]    = tokens.HP
  token_input_map[input.P1.LK.default_name]    = tokens.LK
  token_input_map[input.P1.MK.default_name]    = tokens.MK
  token_input_map[input.P1.HK.default_name]    = tokens.HK
  token_input_map[input.P1.START.default_name] = tokens.START
  token_input_map[input.P1.COIN.default_name]  = tokens.COIN
  token_input_map[input.P2.UP.default_name]    = tokens.UP
  token_input_map[input.P2.DOWN.default_name]  = tokens.DOWN
  token_input_map[input.P2.LEFT.default_name]  = tokens.LEFT
  token_input_map[input.P2.RIGHT.default_name] = tokens.RIGHT
  token_input_map[input.P2.LP.default_name]    = tokens.LP
  token_input_map[input.P2.MP.default_name]    = tokens.MP
  token_input_map[input.P2.HP.default_name]    = tokens.HP
  token_input_map[input.P2.LK.default_name]    = tokens.LK
  token_input_map[input.P2.MK.default_name]    = tokens.MK
  token_input_map[input.P2.HK.default_name]    = tokens.HK
  token_input_map[input.P2.START.default_name] = tokens.START
  token_input_map[input.P2.COIN.default_name]  = tokens.COIN
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

local function activate_inputs()
  for _, inp in ipairs(active_inputs) do
    if inp ~= nil then
      inp:set_value(1)
    end
  end
end

local function deactivate_inputs(inputs)
  for _, inp in ipairs(inputs) do
    if inp ~= nil then
      inp:set_value(0)
    end
  end
end

local function execute_macro(p1, p2)
  local previously_active = active_inputs
  active_inputs = {}
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
  for _, v in pairs(previously_active) do
    for _, w in pairs(active_inputs) do
      if v.default_name == w.default_name then
        v = nil
      end
    end
  end
  deactivate_inputs(previously_active)
  activate_inputs()
  if step < #p1 or step < #p2 then
    step = step + 1
    return true
  else
    step = 1
    return false
  end
end

local play_x0, play_y0 = image_util.scale_coordinate(20, 60, 400, 300)
local play_x1, play_y1 = image_util.scale_coordinate(42, 82, 400, 300)
local function draw_play_icon()
  manager.machine.render.ui_container:draw_quad(play_icon_texture, play_x0, play_y0, play_x1, play_y1)
end

local function process_execution_frame()
  draw_play_icon()
  if #macros > 1 then
    if not execute_macro(macros[1], macros[2]) then
      deactivate_inputs(active_inputs)
      macros = {}
      is_executing_macro = false
    else
      is_executing_macro = true
    end
  else
    is_executing_macro = false
  end
end


local function draw_record_icon()
  manager.machine.render.ui_container:draw_quad(record_icon_texture, play_x0, play_y0, play_x1, play_y1)
end

local function process_recording_frame()
  draw_record_icon()
  macro_recording[#macro_recording + 1] = input.get_currently_pressed()
end

---@param player number
---@return string
local function parse_macro_recording(player)
  local macro_tokens = ''
  local player_index = ''
  if player == 1 then
    macro_tokens = 'P1:'
    player_index = 'P1'
  else
    macro_tokens = 'P2:'
    player_index = 'P2'
  end
  for _, inputs_on_frame in ipairs(macro_recording) do
    local count = 0
    for _, macro_input in pairs(inputs_on_frame[player_index]) do
      count = count + 1
      macro_tokens = macro_tokens .. token_input_map[macro_input.field.default_name]
    end
    if count == 0 then
      macro_tokens = macro_tokens .. ','
    end
  end
  return macro_tokens
end

---@param filename string
---@return nil
local function save_macro(filename)
  local p1_inputs = parse_macro_recording(1)
  local p2_inputs = parse_macro_recording(2)
  -- TODO: process >= n commas into Wn
  -- process_macro_string(p1_inputs)
  -- process_macro_string(p2_inputs)
  local file = io.open(SCRIPT_SETTINGS.macro_dir .. filename, 'w+')
  if not file then return nil end
  file:write(p1_inputs .. '\n' .. p2_inputs)
  file:close()
end

local debounce_recording = 0

---Called externally to begin/end recording a macro
---@param filename string
local function record_macro(filename)
  if is_executing_macro then return end
  if debounce_recording == 0 then
    if is_recording_macro then
      is_recording_macro = false
      debounce_recording = 10
      filename = 'recording.vsr'
      save_macro(filename)
      macro_recording = {}
    else
      is_recording_macro = true
      debounce_recording = 10
    end
  end
end

---Called externally to load a macro
---and begin executing it
---@param filename string
local function load_macro(filename)
  if is_executing_macro or is_recording_macro then return end
  is_executing_macro = true
  filename = 'recording.vsr'
  local p1, p2 = get_macro_file(filename)
  local p1_inputs = nil
  local p2_inputs = nil
  p1_inputs = parse_macro(p1)
  if p1 == nil then
    print('no file!')
    is_executing_macro = false
    return
  end
  if p2 ~= nil then
    p2_inputs = parse_macro(p2)
  end
  table.insert(macros, p1_inputs)
  table.insert(macros, p2_inputs)
end

emu.register_frame_done(function()
  if debounce_recording > 0 then
    debounce_recording = debounce_recording - 1
  end
  if is_executing_macro and not is_recording_macro then
    process_execution_frame()
  end
  if is_recording_macro and not is_executing_macro then
    process_recording_frame()
  end
end)

emu.add_machine_stop_notifier(function()
  play_icon_texture:free()
  record_icon_texture:free()
end)

return {
  ['load_macro'] = load_macro,
  ['record_macro'] = record_macro,
}