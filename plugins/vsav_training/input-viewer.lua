---@alias history_entry { dir_input: number, input: table<string>, duration: number|string }
---@alias input_history table<history_entry>

local game_state = require './vsav_training/game-state'
local inputs = require './vsav_training/utils/input-util'
local image_util = require './vsav_training/utils/image-util'
local render = manager.machine.render
local ui_container = render.ui_container
local sc = image_util.scale_coordinate
local sx = image_util.scale_x
local sy = image_util.scale_y

-- mostly done to precompute values, but also is pseudo-config I guess
local dir_and_but_history_entry_config = {
  entry_height    = sy(21, 300),
  entry_width     = sx(37, 400),
  entry_right_pad = sx(2, 400),

  dir_input_left_pad = sx(2, 400),
  dir_input_top_pad  = sy(5, 300),
  dir_input_width    = sx(11, 400),
  dir_input_height   = sy(16, 300),

  button_inp_left_margin = sx(1, 400),
  button_inp_top_margin  = sy(4, 300),
  button_inp_left_pad    = sx(1, 400),
  button_inp_height      = sy(6, 300),
  button_inp_width       = sx(6, 400),
}

---@type table<render_texture>
local dir_textures = {}
---@type table<render_texture>
local button_textures = {}
local button_filenames = { L = 'L', M = 'M', H = 'H', n = 'no' }
for i = 1, 9 do
  dir_textures[i] = render:texture_alloc(
    image_util.argb32_bitmap_from_square_rgba32_bitmap_data(SCRIPT_SETTINGS.image_dir .. i .. '_dir.data')
  )
end
for k, v in pairs(button_filenames) do
  button_textures[k] = render:texture_alloc(
    image_util.argb32_bitmap_from_square_rgba32_bitmap_data(SCRIPT_SETTINGS.image_dir .. v .. '_button.data')
  )
end

---@type input_history
local p1_input_history = {
  { dir_input = 5, input = {}, duration = 1 }
}
---@type input_history
local p2_input_history = {
  { dir_input = 5, input = {}, duration = 1 }
}

local sorting_table = {
  UP    = 1,
  DOWN  = 2,
  LEFT  = 3,
  RIGHT = 4,
  LP    = 5,
  MP    = 6,
  HP    = 7,
  LK    = 8,
  MK    = 9,
  HK    = 10,
}

local direction_modifiers = {
  UP    = 3,
  DOWN  = -3,
  LEFT  = -1,
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

local function get_button_textures(history_entry)
  local textures = {{ button_textures['n'], button_textures['n'], button_textures['n'] },
                    { button_textures['n'], button_textures['n'], button_textures['n'] }}
  for _, v in pairs(history_entry.input) do
    if v ~= nil and v == 'LP' then textures[1][1] = button_textures['L'] end
    if v ~= nil and v == 'MP' then textures[1][2] = button_textures['M'] end
    if v ~= nil and v == 'HP' then textures[1][3] = button_textures['H'] end
    if v ~= nil and v == 'LK' then textures[2][1] = button_textures['L'] end
    if v ~= nil and v == 'MK' then textures[2][2] = button_textures['M'] end
    if v ~= nil and v == 'HK' then textures[2][3] = button_textures['H'] end
  end
  return textures
end

---Draws a history entry with directional input and buttons at the specified
---coordinates. `x` and `y` should be scaled to the UI container's `xscale`
---and `yscale`.
---@param x number Left edge of entry, scaled relative to UI
---@param y number Top edge of entry, scaled relative to UI
---@param input history_entry
local function draw_dir_and_but_history_entry(x, y, input)
  local entry_left   = x
  local entry_top    = y
  local entry_right  = x + dir_and_but_history_entry_config.entry_width
  local entry_bottom = y + dir_and_but_history_entry_config.entry_height

  local dir_input_left     = x + dir_and_but_history_entry_config.dir_input_left_pad
  local dir_input_right    = x + dir_and_but_history_entry_config.dir_input_left_pad + dir_and_but_history_entry_config.dir_input_width
  local dir_input_top      = y + dir_and_but_history_entry_config.dir_input_top_pad
  local dir_input_bottom   = y + dir_and_but_history_entry_config.dir_input_height

  local button_inp_left        = dir_input_right
  local button_inp_top         = y + dir_and_but_history_entry_config.button_inp_top_margin
  local button_textures_curr   = get_button_textures(input)

  local duration_400_scale_left_pad = 16.5
  if type(input.duration) == 'string' then
    duration_400_scale_left_pad = 16.5
  else
    if input.duration > 9  then duration_400_scale_left_pad = duration_400_scale_left_pad - 1.9 end
    if input.duration > 99 then duration_400_scale_left_pad = duration_400_scale_left_pad - 1.9 end
  end

  local duration_left_pad = sx(duration_400_scale_left_pad, 400)
  local duration_top_pad  = sx(0.5, 400)
  local duration_left     = x + duration_left_pad
  local duration_top      = duration_top_pad + entry_bottom

  ui_container:draw_box(entry_left, entry_top, entry_right, entry_bottom, 0xFF000000, 0xFF000000)
  if duration_left > 0 then
    ui_container:draw_text(duration_left, duration_top, tostring(input.duration), 0xFF93E9BE)
  end
  ui_container:draw_quad(dir_textures[input.dir_input], dir_input_left, dir_input_top, dir_input_right, dir_input_bottom)
  for i = 1, 2 do
    for j = 1, 3 do
      local x_pos = button_inp_left + dir_and_but_history_entry_config.button_inp_left_margin + ((j - 1) * dir_and_but_history_entry_config.button_inp_width + dir_and_but_history_entry_config.button_inp_left_pad)
      local y_pos = button_inp_top + ((i - 1) * dir_and_but_history_entry_config.button_inp_height)
      ui_container:draw_quad(button_textures_curr[i][j], x_pos, y_pos, x_pos + dir_and_but_history_entry_config.button_inp_width, y_pos + dir_and_but_history_entry_config.button_inp_height)
    end
  end
end

emu.register_frame(function()
  if TRAINING_SETTINGS.TRAINING_OPTIONS.show_input_viewer then
    local currently_pressed = inputs.get_currently_pressed()
    local p1_inputs = currently_pressed['P1']
    local p2_inputs = currently_pressed['P2']
    update_history({ P1 = p1_inputs, P2 = p2_inputs })
  end
end)

local display_x1, display_y1 = sc(0, 265, 400, 300)
local display_x2, display_y2 = sc(400, 300, 400, 300)
local input_history_start_x, input_history_start_y = sc(360, 267, 400, 300)
emu.register_frame_done(function()
  if TRAINING_SETTINGS.TRAINING_OPTIONS.show_input_viewer and game_state and game_state.match_has_begun() then
    ui_container:draw_box(display_x1, display_y1, display_x2, display_y2, 0x7F555555, 0x7F555555)
    for i = 0, 10 do
      local start_x = input_history_start_x - (i * dir_and_but_history_entry_config.entry_width) - (i * dir_and_but_history_entry_config.entry_right_pad)
      if p1_input_history[#p1_input_history-i] == nil then break end
      draw_dir_and_but_history_entry(start_x, input_history_start_y, p1_input_history[#p1_input_history - i])
    end
  end
end)

emu.register_stop(function()
  for _, texture in pairs(dir_textures) do
    texture:free()
  end
  for _, texture in pairs(button_textures) do
    texture:free()
  end
end)

return {
  ['p1_input_history'] = p1_input_history,
  ['p2_input_history'] = p2_input_history,
}