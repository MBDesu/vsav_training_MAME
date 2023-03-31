local function toggle_set_enabled(menu_item, state)
  if menu_item.is_enabled == state then
    return state, false
  end
  if not state then
    menu_item.is_enabled = false
    menu_item.label = menu_item.label_off
    menu_item.nav_label = menu_item.nav_label_off
  else
    menu_item.is_enabled = true
    menu_item.label = menu_item.label_on
    menu_item.nav_label = menu_item.nav_label_on
  end
  if menu_item.config_obj then
    menu_item.config_obj.object[menu_item.config_obj.property_name] = not menu_item.config_obj.object[menu_item.config_obj.property_name]
  end
  return true, true
end

local function create_toggle_menu_item(name, label_on, label_off, nav_label_on, nav_label_off, setting_object, setting_property, enabled)
  local label = label_off
  local nav_label = nav_label_off
  local is_enabled = enabled
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
    label = label_on
    nav_label = nav_label_on
  else
    label = label_off
    nav_label = nav_label_off
  end

  return {
    name = name,
    label = label,
    label_on = label_on,
    label_off = label_off,
    nav_label = nav_label,
    nav_label_on = nav_label_on,
    nav_label_off = nav_label_off,
    is_enabled = is_enabled,
    set_enabled = toggle_set_enabled,
    config_obj = config_obj,
    type = 'toggle'
  }
end

local dummy_options_infinite_health = create_toggle_menu_item('Infinite Health', 'On', 'Off', 'l', 'r', SETTINGS.DUMMY_SETTINGS, 'infinite_health', true)
local dummy_options_menu = {
  dummy_options_infinite_health
}
-- local settings_options_menu = {}
-- local game_options_menu = {}

local function populate_dummy_menu()
  local menu = {}
  for _, item in pairs(dummy_options_menu) do
    menu[#menu + 1] = { item.name, item.label, item.nav_label }
  end
  return menu
end

local function dummy_menu_callback(index, event)
  local menu_item = dummy_options_menu[index]
  if not menu_item then return false end
  if event == 'select' or event == 'right' or event == 'left' then
    if menu_item.type == 'toggle' then
      local state, chg = menu_item:set_enabled(not menu_item.is_enabled)
      return state, chg
    end
  end
end

-- local function training_options_menu_callback(index, event)
-- end

-- local function game_settings_menu_callback(index, event)
-- end

emu.register_menu(dummy_menu_callback, populate_dummy_menu, "Dummy Options")
-- emu.register_menu(training_options_menu_callback, function() return settings_options_menu end, "Training Options")
-- emu.register_menu(game_settings_menu_callback, function() return game_options_menu end, "Game Settings")