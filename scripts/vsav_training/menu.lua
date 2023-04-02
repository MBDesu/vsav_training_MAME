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
  return true, true
end

local function set_value(menu_item, state)
  if menu_item.type == 'toggle' then
    return toggle_set_enabled(menu_item, state)
  elseif menu_item.type == 'integer' then
    return set_integer_value(menu_item, state)
  end
end

local function create_heading_item(text)
  return { name = text, display_value = '', nav_label = 'heading' }
end

local function create_separator_item()
  return { name = '---', display_value = '', nav_label = '' }
end

local function create_default_all_item()
  return { name = 'Default All', display_value = '', nav_label = '', type = 'default all' }
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
  local change = 0
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
  if change == 0 then change = menu_item.display_value end
  return change
end

local function handle_menu_change(menu, menu_item, event)
  if not menu_item then return false end
  if menu_item.type == 'toggle' then
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

local dummy_settings_menu = {
  create_heading_item('Dummy Options'),
  create_toggle_menu_item('P1 Infinite Health', 'On', 'Off', 'r', 'l', SETTINGS.DUMMY_SETTINGS, 'p1_infinite_health', true),
  create_integer_menu_item('P1 Max Health', 1, 288, SETTINGS.DUMMY_SETTINGS, 'p1_max_health', 288),
  create_integer_menu_item('P1 Refill Health Delay (seconds)', 0, 60, SETTINGS.DUMMY_SETTINGS, 'p1_delay_to_refill', 0),
  create_separator_item(),
  create_toggle_menu_item('P2 Infinite Health', 'On', 'Off', 'r', 'l', SETTINGS.DUMMY_SETTINGS, 'p2_infinite_health', true),
  create_integer_menu_item('P2 Max Health', 1, 288, SETTINGS.DUMMY_SETTINGS, 'p2_max_health', 288),
  create_integer_menu_item('P2 Refill Health Delay (seconds)', 0, 60, SETTINGS.DUMMY_SETTINGS, 'p2_delay_to_refill', 0),
  create_separator_item(),
  create_default_all_item(),
}
local training_options_menu = {
  create_heading_item('Training Options'),
  create_toggle_menu_item('Infinite Time', 'On', 'Off', 'r', 'l', SETTINGS.TRAINING_OPTIONS, 'infinite_time', true),
  create_toggle_menu_item('Show Hitboxes', 'Yes', 'No', 'r', 'l', SETTINGS.TRAINING_OPTIONS, 'show_hitboxes', true),
  create_separator_item(),
  create_default_all_item(),
}

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

-- local function game_settings_menu_callback(index, event)
-- end

emu.register_menu(dummy_menu_callback, populate_dummy_menu, 'Dummy Settings')
emu.register_menu(training_options_menu_callback, populate_training_options, 'Training Options')
-- emu.register_menu(game_settings_menu_callback, function() return game_options_menu end, "Game Settings")