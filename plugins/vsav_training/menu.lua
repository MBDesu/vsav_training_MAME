local game_state = require './vsav_training/game-state'
local file_util = require './vsav_training/utils/file-util'
local macro = require './vsav_training/macro/macro'

local hotkey_menu = false
local hotkey_list = {}
local poller

local function toggle_set_enabled(menu_item, state)
  if menu_item.is_enabled == state then
    return state, false
  end
  if not state then
    menu_item.is_enabled = false
    menu_item.display_value = menu_item.display_value_off
    menu_item.nav_label = menu_item.nav_label_off
  else
    menu_item.is_enabled = true
    menu_item.display_value = menu_item.display_value_on
    menu_item.nav_label = menu_item.nav_label_on
  end
  if menu_item.config_obj then
    menu_item.config_obj.object[menu_item.config_obj.property_name] = not menu_item.config_obj.object[menu_item.config_obj.property_name]
  end
  file_util.save_training_settings()
  return true, true
end

local function set_integer_value(menu_item, state)
  local function set_integer_nav_label()
    if menu_item.is_entering_text then
      menu_item.nav_label = ''
    elseif state >= menu_item.max_value then
      menu_item.nav_label = 'l'
    elseif state <= menu_item.min_value then
      menu_item.nav_label = 'r'
    else
      menu_item.nav_label = 'lr'
    end
  end
  if menu_item.display_value == state then
    local curr_nav_label = menu_item.nav_label
    set_integer_nav_label()
    local is_text_mode_change = menu_item.is_entering_text or curr_nav_label ~= menu_item.nav_label
    if is_text_mode_change then return true, true else return state, false end
  end
  if not state then
    menu_item.display_value = menu_item.min_value
    menu_item.nav_label = 'r'
  else
    set_integer_nav_label()
    menu_item.display_value = state
    if menu_item.config_obj then
      menu_item.config_obj.object[menu_item.config_obj.property_name] = menu_item.display_value
    end
  end
  file_util.save_training_settings()
  return true, true
end

local function set_value(menu_item, state)
  if menu_item.type == 'toggle' then
    return toggle_set_enabled(menu_item, state)
  elseif menu_item.type == 'integer' then
    return set_integer_value(menu_item, state)
  end
end

local function create_generic_menu_item(name, display_value, nav_label)
  return { name = name, display_value = display_value, nav_label = nav_label }
end

local function create_heading_menu_item(text)
  return { name = text, display_value = '', nav_label = 'heading' }
end

local function create_separator_menu_item()
  return { name = '---', display_value = '', nav_label = '' }
end

local function create_default_all_menu_item()
  return { name = 'Default All', display_value = '', nav_label = '', type = 'default all' }
end

local function create_hotkeyable_menu_item(name, fn)
  return {
    name = name,
    display_value = '',
    nav_label = '',
    callback = fn,
    type = 'hotkeyable'
  }
end

local function create_toggle_menu_item(name, display_value_on, display_value_off, nav_label_on, nav_label_off, setting_object, setting_property, enabled_by_default)
  local display_value = display_value_off
  local nav_label = nav_label_off
  local is_enabled = enabled_by_default
  local config_obj = {
    object = setting_object,
    property_name = setting_property,
  }
  function config_obj:sync_to_settings()
    self.object[self.property_name] = is_enabled
  end
  function config_obj:sync_from_settings()
    is_enabled = self.object[self.property_name]
  end
  if not setting_object or not setting_property then
    config_obj = nil
  else
    config_obj:sync_from_settings()
  end
  if is_enabled then
    display_value = display_value_on
    nav_label = nav_label_on
  else
    display_value = display_value_off
    nav_label = nav_label_off
  end

  return {
    name = name,
    display_value = display_value,
    display_value_on = display_value_on,
    display_value_off = display_value_off,
    nav_label = nav_label,
    nav_label_on = nav_label_on,
    nav_label_off = nav_label_off,
    is_enabled = is_enabled,
    default_value = enabled_by_default,
    set_value = set_value,
    config_obj = config_obj,
    type = 'toggle'
  }
end

local function create_integer_menu_item(name, min_value, max_value, setting_object, setting_property, default_value)
  local display_value = default_value
  local nav_label = 'lr'
  local config_obj = {
    object = setting_object,
    property_name = setting_property,
  }
  if not setting_object or not setting_property then
    config_obj = nil
  else
    display_value = config_obj.object[config_obj.property_name]
  end
  if not min_value then min_value = 0 end
  if not max_value then max_value = 0xFFFF end
  if display_value >= max_value then
    display_value = max_value
    nav_label = 'l'
  elseif display_value <= min_value then
    display_value = min_value
    nav_label = 'r'
  end
  return {
    name = name,
    display_value = display_value,
    min_value = min_value,
    max_value = max_value,
    nav_label = nav_label,
    config_obj = config_obj,
    default_value = default_value,
    is_entering_text = false,
    set_value = set_value,
    type = 'integer'
  }
end

local function handle_integer_menu_item_change(menu_item, event)
  local change = nil
  local did_select_menu_item = event == 'select'
  local did_enter_number = menu_item.is_entering_text and tonumber(event) ~= nil and tonumber(event) >= 0x30 and tonumber(event) <= 0x39
  local did_finish_entering_text = (event == 'back' or event == 'select' or tonumber(event) and tonumber(event) == 0x9) and menu_item.is_entering_text
  local did_backspace = menu_item.is_entering_text and tonumber(event) ~= nil and tonumber(event) == 0x8

  if event == 'left' and not menu_item.is_entering_text then
    change = menu_item.display_value - 1
  elseif event == 'right' and not menu_item.is_entering_text then
    change = menu_item.display_value + 1
  elseif did_select_menu_item and not menu_item.is_entering_text then
    menu_item.is_entering_text = true
  -- TODO: no event fires on pressing a controller button to exit the training
  -- menu, so if user is in input mode and then exits via controller button,
  -- did_finish_entering_text is never properly flagged
  --
  -- Likely solution: a timed callback that sets menu_item.is_entering_text to
  -- `false` after a minute or so
  -- TODO: investigate uiinput:reset() RE: above?
  elseif did_finish_entering_text then
    menu_item.display_value = math.min(menu_item.max_value, math.max(menu_item.min_value, menu_item.display_value))
    menu_item.is_entering_text = false
  elseif did_enter_number then
    change = (tonumber(menu_item.display_value) * 10) + ASCII_KEYCODE_TO_INT(tonumber(event))
  elseif did_backspace then
    if menu_item.display_value then
      if tonumber(menu_item.display_value) < 10 then
        menu_item.display_value = 0
      else
        change = math.floor(tonumber(menu_item.display_value) / 10)
      end
    end
  end
  if change == nil then change = menu_item.display_value end
  return change
end

local function handle_menu_change(menu, menu_item, event)
  if not menu_item then return false end
  if event == 'clear' then
    if menu_item.set_value ~= nil and menu_item.default_value ~= nil then
      menu_item:set_value(menu_item.default_value)
      return true
    end
  elseif menu_item.type == 'toggle' then
    if event == 'right' or event == 'left' then
      local state, chg = menu_item:set_value(not menu_item.is_enabled)
      return state, chg
    end
  elseif menu_item.type == 'integer' then
    local change = handle_integer_menu_item_change(menu_item, event)
    local state, chg = menu_item:set_value(change)
    return state, chg
  elseif menu_item.type == 'default all' then
    if event == 'select' then
      for _, v in pairs(menu) do
        if v.set_value ~= nil and v.default_value ~= nil then
          v:set_value(v.default_value)
        end
      end
    end
    return true
  end
end

local function switch_polling_helper(starting_sequence)
  local helper = {}

  local machine = manager.machine
  local cancel = machine.ioport:token_to_input_type('UI_CANCEL')
  local cancel_prompt = manager.ui:get_general_input_setting(cancel)
  local input = machine.input
  local uiinput = machine.uiinput
  local _poller = input:switch_sequence_poller()
  local modified_ticks = 0

  if starting_sequence then
    _poller:start(starting_sequence)
  else
    _poller:start()
  end

  function helper:overlay(items, selection, flags)
    if flags then
      flags = flags .. ' nokeys'
    else
      flags = 'nokeys'
    end
    return items, selection, flags
  end

  function helper:poll()
    if (modified_ticks == 0) and _poller.modified then
      modified_ticks = emu.osd_ticks()
    end

    if uiinput:pressed(cancel) then
      machine:popmessage()
      uiinput:reset()
      if (not _poller.modified) or (modified_ticks == emu.osd_ticks()) then
        self.sequence = nil
        return true
      else
        self.sequence = nil
        return true
      end
    elseif _poller:poll() then
      uiinput:reset()
      if _poller.valid then
        machine:popmessage()
        self.sequence = _poller.sequence
        return true
      else
        machine:popmessage('Invalid combination entered')
        self.sequence = nil
        return true
      end
    else
      machine:popmessage(string.format('Enter combination or press %s to cancel\n%s', cancel_prompt, input:seq_name(_poller.sequence)))
      return false
    end
  end
  return helper
end

-----------------------------------------------------
-- ADD NEW MENU STUFF HERE
-----------------------------------------------------
local dummy_settings_menu = {
  create_heading_menu_item('Dummy Options'),
  create_toggle_menu_item('P1 Infinite Health', 'On', 'Off', 'r', 'l', TRAINING_SETTINGS.DUMMY_SETTINGS, 'p1_infinite_health', true),
  create_toggle_menu_item('P1 Infinite Meter', 'On', 'Off', 'r', 'l', TRAINING_SETTINGS.DUMMY_SETTINGS, 'p1_infinite_meter', true),
  create_integer_menu_item('P1 Max Health', 1, 288, TRAINING_SETTINGS.DUMMY_SETTINGS, 'p1_max_health', 288),
  create_integer_menu_item('P1 Refill Health Delay (seconds)', 0, 60, TRAINING_SETTINGS.DUMMY_SETTINGS, 'p1_delay_to_refill', 0),
  create_separator_menu_item(),
  create_toggle_menu_item('P2 Infinite Health', 'On', 'Off', 'r', 'l', TRAINING_SETTINGS.DUMMY_SETTINGS, 'p2_infinite_health', true),
  create_toggle_menu_item('P2 Infinite Meter', 'On', 'Off', 'r', 'l', TRAINING_SETTINGS.DUMMY_SETTINGS, 'p2_infinite_meter', true),
  create_integer_menu_item('P2 Max Health', 1, 288, TRAINING_SETTINGS.DUMMY_SETTINGS, 'p2_max_health', 288),
  create_integer_menu_item('P2 Refill Health Delay (seconds)', 0, 60, TRAINING_SETTINGS.DUMMY_SETTINGS, 'p2_delay_to_refill', 0),
  create_separator_menu_item(),
  create_generic_menu_item(string.format('Press %s to default', manager.ui:get_general_input_setting(manager.machine.ioport:token_to_input_type('UI_CLEAR'))), '', 'off'),
  create_separator_menu_item(),
  create_default_all_menu_item(),
}

local training_options_menu = {
  create_heading_menu_item('Training Options'),
  create_toggle_menu_item('Infinite Time', 'On', 'Off', 'r', 'l', TRAINING_SETTINGS.TRAINING_OPTIONS, 'infinite_time', true),
  create_toggle_menu_item('Disable Taunts', 'Yes', 'No', 'r', 'l', TRAINING_SETTINGS.TRAINING_OPTIONS, 'disable_taunts', false),
  create_separator_menu_item(),
  create_toggle_menu_item('Show Hitboxes', 'Yes', 'No', 'r', 'l', TRAINING_SETTINGS.TRAINING_OPTIONS, 'show_hitboxes', true),
  create_toggle_menu_item('Fill Hitboxes', 'Yes', 'No', 'r', 'l', TRAINING_SETTINGS.TRAINING_OPTIONS, 'fill_hitboxes', true),
  create_toggle_menu_item('Blank Screen', 'Yes', 'No', 'r', 'l', TRAINING_SETTINGS.TRAINING_OPTIONS, 'blank_screen', false),
  create_separator_menu_item(),
  create_toggle_menu_item('Show Input Viewer', 'Yes', 'No', 'r', 'l', TRAINING_SETTINGS.TRAINING_OPTIONS, 'show_input_viewer', true),
  create_separator_menu_item(),
  create_generic_menu_item(string.format('Press %s to default', manager.ui:get_general_input_setting(manager.machine.ioport:token_to_input_type('UI_CLEAR'))), '', 'off'),
  create_separator_menu_item(),
  create_default_all_menu_item(),
}

local game_settings_menu = {
  create_heading_menu_item('Game Settings'),
  create_integer_menu_item('Game Speed', 0, 3, TRAINING_SETTINGS.GAME_SETTINGS, 'game_speed', 3),
  create_separator_menu_item(),
  create_generic_menu_item(string.format('Press %s to default', manager.ui:get_general_input_setting(manager.machine.ioport:token_to_input_type('UI_CLEAR'))), '', 'off'),
  create_separator_menu_item(),
  create_default_all_menu_item()
}

local extra_functions_menu = {
  create_heading_menu_item('Extra Functions'),
  create_hotkeyable_menu_item('Return to Character Select', game_state.return_to_character_select),
  create_hotkeyable_menu_item('Run Macro', macro.load_macro),
  create_separator_menu_item(),
}

local function load_hotkeys()
  local hotkeys = file_util.parse_json_file_to_object(SCRIPT_SETTINGS.hotkeys_settings_file)
  ---@diagnostic disable-next-line: param-type-mismatch
    for _, hotkey in ipairs(hotkeys) do
      for _, item in pairs(extra_functions_menu) do
        if hotkey.desc == item.name and item.type == 'hotkeyable' then
          item.hotkeys = { pressed = false, keys = manager.machine.input:seq_from_tokens(hotkey.keys) }
        end
      end
    end
end

local function populate_dummy_menu()
  local menu = {}
  for _, item in pairs(dummy_settings_menu) do
    menu[#menu + 1] = { item.name, item.display_value, item.nav_label }
  end
  return menu, nil, 'lrrepeat'
end

local function dummy_menu_callback(index, event)
  local menu = dummy_settings_menu
  local menu_item = menu[index]
  return handle_menu_change(menu, menu_item, event)
end

local function populate_training_options()
  local menu = {}
  for _, item in pairs(training_options_menu) do
    menu[#menu + 1] = { item.name, item.display_value, item.nav_label }
  end
  return menu, nil, 'lrrepeat'
end

local function training_options_menu_callback(index, event)
  local menu = training_options_menu
  local menu_item = menu[index]
  return handle_menu_change(menu, menu_item, event)
end

local function populate_game_settings()
  local menu = {}
  for _, item in pairs(game_settings_menu) do
    menu[#menu + 1] = { item.name, item.display_value, item.nav_label }
  end
  return menu, nil, 'lrrepeat'
end

local function game_settings_menu_callback(index, event)
  local menu = game_settings_menu
  local menu_item = menu[index]
  return handle_menu_change(menu, menu_item, event)
end

local function save_hotkeys()
  local hotkeys = {}
  for _, item in ipairs(extra_functions_menu) do
    if item.type == 'hotkeyable' and item.hotkeys then
      local hotkey = { desc = item.name, keys = manager.machine.input:seq_to_tokens(item.hotkeys.keys) }
      if hotkey.keys ~= '' then
        hotkeys[#hotkeys + 1] = hotkey
      end
    end
  end
  if #hotkeys > 0 then
    file_util.parse_object_to_json_file(hotkeys, SCRIPT_SETTINGS.hotkeys_settings_file)
  end
end


-- don't look at this, you'll go insane
local function populate_extra_functions()
  local menu = {}
  if hotkey_menu then
    local input = manager.machine.input
    menu[1] = { 'Select item to hotkey', '', 'off' }
    menu[2] = { string.format('Press %s to clear', manager.ui:get_general_input_setting(manager.machine.ioport:token_to_input_type('UI_CLEAR'))), '', 'off' }
    menu[3] = { '---', '', 'off' }
    hotkey_list = {}
    local function hotkey_callback(menu_item, event)
      if poller then
        if poller:poll() then
          if poller.sequence then
            menu_item.hotkeys = { pressed = false, keys = poller.sequence }
          end
          save_hotkeys()
          poller = nil
          return true
        end
      elseif event == 'clear' then
        menu_item.hotkeys = nil
        return true
      elseif event == 'select' then
        poller = switch_polling_helper()
        return true
      end
      return false
    end

    for _, item in pairs(extra_functions_menu) do
      if item.type and item.type == 'hotkeyable' then
        local setting = item.hotkeys and input:seq_name(item.hotkeys.keys) or 'None'
        menu[#menu + 1] = { item.name, setting, item.nav_label }
        hotkey_list[#hotkey_list + 1] = function(event) return hotkey_callback(item, event) end
      end
    end
    menu[#menu + 1] = { '---', '', '' }
    menu[#menu + 1] = { 'Done', '', '' }
    if poller then
      return poller:overlay(menu)
    else
      return menu
    end
  end
  for _, item in pairs(extra_functions_menu) do
    menu[#menu + 1] = { item.name, item.display_value, item.nav_label }
  end
  menu[#menu + 1] = { 'Set hotkeys', '', '' }
  return menu
end

local function extra_functions_menu_callback(index, event)
  if hotkey_menu then
    if event == 'back' then
      hotkey_menu = false
      return true
    else
      index = index - 3
      if index >= 1 and index <= #hotkey_list then
        hotkey_list[index](event)
        return true
      elseif index == #hotkey_list + 2 and event == 'select' then
        hotkey_menu = false
        return true
      end
    end
    return false
  end
  if index > #extra_functions_menu and event == 'select' then
    index = index - #extra_functions_menu
    if index == 1 then
      hotkey_menu = true
    end
    return true
  end
  local menu = extra_functions_menu
  local menu_item = menu[index]
  if not menu_item then return false end
  if event == 'select' and menu_item.type == 'hotkeyable' then
    menu_item:callback()
  end
  return false
end

emu.register_menu(dummy_menu_callback, populate_dummy_menu, 'Dummy Settings')
emu.register_menu(training_options_menu_callback, populate_training_options, 'Training Options')
emu.register_menu(game_settings_menu_callback, populate_game_settings, 'Game Settings')
emu.register_menu(extra_functions_menu_callback, populate_extra_functions, 'Extra Functions')

emu.register_frame(function()
  for _, item in ipairs(extra_functions_menu) do
    if item.hotkeys and item.hotkeys.keys then
      if manager.machine.input:seq_pressed(item.hotkeys.keys) then
        if not item.hotkeys.pressed then
          item:callback()
        end
      end
    end
  end
end)

return {
  ['register_prestart'] = load_hotkeys
}