local inputs = require './scripts/vsav_training/utils/input-util'
local screen = manager.machine.screens[':screen'];

---@alias history_entry { input: table<string>, duration: number }
---@alias input_history table<history_entry>

---@type input_history
local p1_input_history = {
  { input = {}, duration = 1 }
}
---@type input_history
local p2_input_history = {
  { input = {}, duration = 1}
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

---@param history_entry history_entry
---@return number
local function convert_direction_to_numpad(history_entry)
  local numpad = 5
  for _, v in pairs(history_entry.input) do
    if direction_modifiers[v] then numpad = numpad + direction_modifiers[v] end
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

---Honestly just a function that checks if two string tables are the same
---@param current_player_inputs table<string>
---@param last_player_input table<string>
---@return boolean
local function needs_update(current_player_inputs, last_player_input)
  -- easy case to check; if the lengths don't match, then there's definitely new input
  if #current_player_inputs ~= #last_player_input then
    return true
  end
  -- lengths match, but what if player switched buttons in 1F?
  -- iterate over the (sorted) inputs and see if they all match
  -- maybe could also table.concat but whatever
  for i, input in ipairs(current_player_inputs) do
    if input ~= last_player_input[i] then return true end
  end
  return false
end

---@param player 'P1'|'P2'
---@param current_player_inputs table<string>
local function update_player_history(player, current_player_inputs)
  sort_inputs(current_player_inputs)
  local player_input_history
  if   player == 'P1' then player_input_history = p1_input_history
  else player_input_history = p2_input_history end
  local last_player_input = player_input_history[#player_input_history].input
  if needs_update(current_player_inputs, last_player_input) then
    player_input_history[#player_input_history + 1] = { input = current_player_inputs, duration = 1 }
  else
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
  local filter = function(input)
    return do_track_inputs[input]
  end
  local currently_pressed = inputs.get_currently_pressed()
  local p1_inputs = FILTER_TABLE_BY_KEY(currently_pressed['P1'], filter)
  local p2_inputs = FILTER_TABLE_BY_KEY(currently_pressed['P2'], filter)
  update_history({ P1 = p1_inputs, P2 = p2_inputs })
  PRINT_TABLE(p1_input_history[#p1_input_history])
end)