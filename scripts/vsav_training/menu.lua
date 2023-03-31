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
  -- print('toggled', menu_item.name, tostring(menu_item.is_enabled))
  if menu_item.config_obj then
    menu_item.config_obj.object[menu_item.config_obj.property_name] = not menu_item.config_obj.object[menu_item.config_obj.property_name]
  end
  return true, true
end

local function set_integer_value(menu_item, state)
  print('in set_integer_value')
  if menu_item.display_value == state then
    return state, false
  end
  if not state then
    menu_item.display_value = menu_item.min_value
    menu_item.nav_label = 'r'
  else
    if state >= menu_item.max_value then
      menu_item.display_value = menu_item.max_value
      menu_item.nav_label = 'l'
    elseif state <= menu_item.min_value then
      menu_item.display_value = menu_item.min_value
      menu_item.nav_label = 'r'
    else
      menu_item.display_value = state
      menu_item.nav_label = 'lr'
    end
    if menu_item.config_obj then
      menu_item.config_obj.object[menu_item.config_obj.property_name] = menu_item.display_value
    end
  end
  return true, true
end

local function set_value(menu_item, state)
  print('in set_value')
  if menu_item.type == 'toggle' then
    return toggle_set_enabled(menu_item, state)
  elseif menu_item.type == 'integer' then
    return set_integer_value(menu_item, state)
  end
end

local function create_toggle_menu_item(name, display_value_on, display_value_off, nav_label_on, nav_label_off, setting_object, setting_property, enabled)
  local display_value = display_value_off
  local nav_label = nav_label_off
  local is_enabled = enabled
  local default_value = enabled
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
    default_value = default_value,
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
    set_value = set_value,
    type = 'integer'
  }
end

local dummy_settings_menu = {
  create_toggle_menu_item('Dummy Settings', '', '', 'heading', 'heading', nil, nil, false),
  create_toggle_menu_item('Infinite Health', 'On', 'Off', 'r', 'l', SETTINGS.DUMMY_SETTINGS, 'infinite_health', true),
  create_integer_menu_item('Max Health', 1, 288, SETTINGS.DUMMY_SETTINGS, 'max_health', 288)
}
local training_options_menu = {
  create_toggle_menu_item('Training Options', '', '', 'heading', 'heading', nil, nil, false),
  -- create_toggle_menu_item('Infinite Time', 'On', 'Off', 'r', 'l', SETTINGS.TRAINING_OPTIONS, 'infinite_time', true),
  create_toggle_menu_item('Show Hitboxes', 'Yes', 'No', 'r', 'l', SETTINGS.TRAINING_OPTIONS, 'show_hitboxes', true),
}

local function handle_menu_change(menu_item, event)
  if not menu_item then return false end
  if event == 'right' or event == 'left' then
    if menu_item.type == 'toggle' then
      local state, chg = menu_item:set_value(not menu_item.is_enabled)
      return state, chg
    elseif menu_item.type == 'integer' then
      local change
      if event == 'left' then change = -1
      else change = 1 end
      local state, chg = menu_item:set_value(menu_item.display_value + change)
      return state, chg
    end
  end
end

local function populate_dummy_menu()
  local menu = {}
  for _, item in pairs(dummy_settings_menu) do
    menu[#menu + 1] = { item.name, item.display_value, item.nav_label }
  end
  return menu
end

local function dummy_menu_callback(index, event)
  local menu_item = dummy_settings_menu[index]
  return handle_menu_change(menu_item, event)
end

local function populate_training_options()
  local menu = {}
  for _, item in pairs(training_options_menu) do
    menu[#menu + 1] = { item.name, item.display_value, item.nav_label }
  end
  return menu
end

local function training_options_menu_callback(index, event)
  local menu_item = training_options_menu[index]
  return handle_menu_change(menu_item, event)
end

-- local function game_settings_menu_callback(index, event)
-- end

emu.register_menu(dummy_menu_callback, populate_dummy_menu, 'Dummy Settings')
emu.register_menu(training_options_menu_callback, populate_training_options, 'Training Options')
-- emu.register_menu(game_settings_menu_callback, function() return game_options_menu end, "Game Settings")