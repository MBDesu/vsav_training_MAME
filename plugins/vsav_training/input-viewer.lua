local inputs = require './vsav_training/utils/input-util'

local input_viewer_view_index = 0
local normal_4_3_view_index = 0
local current_view_index = manager.machine.render.ui_target.view_index

for i, view in ipairs(manager.machine.render.ui_target.view_names) do
  if input_viewer_view_index ~= 0 and normal_4_3_view_index ~= 0 then break end
  if view == 'Input Display' then
    input_viewer_view_index = i
  elseif view == 'Screen 0 Standard (4:3)' then
    normal_4_3_view_index = i
  end
end

---@alias history_entry { dir_input: number, input: table<string>, duration: number|string }
---@alias input_history table<history_entry>

---@type input_history
local p1_input_history = {
  { dir_input = 5, input = {}, duration = 1 }
}
---@type input_history
local p2_input_history = {
  { dir_input = 5, input = {}, duration = 1 }
}

local do_track_inputs = {
  UP = true,
  DOWN = true,
  LEFT = true,
  RIGHT = true,
  LP = true,
  MP = true,
  HP = true,
  LK = true,
  MK = true,
  HK = true,
  COIN = false,
  START = false,
}

local sorting_table = {
  UP = 1,
  DOWN = 2,
  LEFT = 3,
  RIGHT = 4,
  LP = 5,
  MP = 6,
  HP = 7,
  LK = 8,
  MK = 9,
  HK = 10,
}

local direction_modifiers = {
  UP = 3,
  DOWN = -3,
  LEFT = -1,
  RIGHT = 1,
}

---@param input_entry table<string>
---@return number
local function parse_dir_numpad(input_entry)
  local numpad = 5
  for _, v in ipairs(input_entry) do
    if direction_modifiers[v] then
      numpad = numpad + direction_modifiers[v]
    end
  end
  return numpad
end

---@param player_inputs table<string>
local function sort_inputs(player_inputs)
  table.sort(player_inputs, function(a, b)
    if sorting_table[a] < sorting_table[b] then return true end
    return false
  end)
end

---@param current_player_dir_input number
---@param current_player_button_input table<string>
---@param last_player_dir_input number
---@param last_player_button_input table<string>
---@return boolean
local function needs_update(current_player_dir_input, current_player_button_input, last_player_dir_input, last_player_button_input)
  -- easy case to check; if the dir inputs don't match or the button inputs differ in number,
  -- then we def need an update
  if current_player_dir_input ~= last_player_dir_input or #current_player_button_input ~= #last_player_button_input then
    return true
  end
  -- lengths and dirs match, but what if player switched buttons in 1F?
  -- iterate over the (sorted) inputs and see if they all match
  -- maybe could also table.concat but whatever
  for i, input in ipairs(current_player_button_input) do
    if input ~= last_player_button_input[i] then return true end
  end
  return false
end

---@param current_player_inputs table<string>
---@return number current_player_dir_input, table<string> current_player_button_input 
local function parse_dir_and_button_inputs(current_player_inputs)
  local dir_input = parse_dir_numpad(current_player_inputs)
  local button_input = {}
  for _, button in ipairs(current_player_inputs) do
    if button ~= 'UP' and button ~= 'DOWN' and button ~= 'LEFT' and button ~= 'RIGHT' then
      button_input[#button_input + 1] = button
    end
  end
  return dir_input, button_input
end

---@param player 'P1'|'P2'
---@param current_player_inputs table<string>
local function update_player_history(player, current_player_inputs)
  sort_inputs(current_player_inputs)
  local current_player_dir_input, current_player_button_input = parse_dir_and_button_inputs(current_player_inputs)

  local player_input_history

  if   player == 'P1' then player_input_history = p1_input_history
  else player_input_history = p2_input_history end

  local last_player_dir_input = player_input_history[#player_input_history].dir_input
  local last_player_button_input = player_input_history[#player_input_history].input

  if needs_update(current_player_dir_input, current_player_button_input, last_player_dir_input, last_player_button_input) then
    player_input_history[#player_input_history + 1] = { dir_input = current_player_dir_input, input = current_player_button_input, duration = 1 }
    if #player_input_history > 2000 then
      for i = 1, 1000 do
        player_input_history[i] = nil
      end
    end
  else
    local duration = player_input_history[#player_input_history].duration
    if duration == '-' then return end
    if duration > 998 then player_input_history[#player_input_history].duration = '-' return end
    player_input_history[#player_input_history].duration = player_input_history[#player_input_history].duration + 1
  end
end

---@param currently_pressed table<{ P1: inputs, P2: inputs }>
local function update_history(currently_pressed)
  for player, player_inputs in pairs(currently_pressed) do
    local translated_player_inputs = {}
    for player_input, _ in pairs(player_inputs) do
      translated_player_inputs[#translated_player_inputs + 1] = player_input
    end
    update_player_history(tostring(player), translated_player_inputs)
  end
end

emu.register_frame(function()
  if TRAINING_SETTINGS.TRAINING_OPTIONS.show_input_viewer then

    if current_view_index ~= input_viewer_view_index then
      manager.machine.render.ui_target.view_index = input_viewer_view_index
      current_view_index = input_viewer_view_index
    end
    local filter = function(input)
      return do_track_inputs[input]
    end
    local currently_pressed = inputs.get_currently_pressed()
    local p1_inputs = FILTER_TABLE_BY_KEY(currently_pressed['P1'], filter)
    local p2_inputs = FILTER_TABLE_BY_KEY(currently_pressed['P2'], filter)
    update_history({ P1 = p1_inputs, P2 = p2_inputs })
  else
    if current_view_index ~= normal_4_3_view_index then
      manager.machine.render.ui_target.view_index = normal_4_3_view_index
      current_view_index = normal_4_3_view_index
    end
  end
end)

return {
  ['p1_input_history'] = p1_input_history,
  ['p2_input_history'] = p2_input_history,
}