TRAINING_SETTINGS = {
  DUMMY_SETTINGS = {
    p1_infinite_health = true,
    p1_infinite_meter = true,
    p1_max_health = 288,
    p1_delay_to_refill = 0,
    p2_infinite_health = true,
    p2_infinite_meter = true,
    p2_hold_direction = 'N',
    p2_max_health = 288,
    p2_delay_to_refill = 0,
  },
  TRAINING_OPTIONS = {
    show_hitboxes = true,
    fill_hitboxes = true,
    show_only_hitboxes = false,
    infinite_time = true,
    disable_taunts = false,
    show_input_viewer = true,
    hide_background = false,
    hide_life_bars = false,
    hide_meters = false,
  },
  GAME_SETTINGS = {
    game_speed = 3,
  },
}

SCRIPT_SETTINGS = {
  training_settings_file = 'plugins/vsav_training/training_settings.json',
  hotkeys_settings_file = 'plugins/vsav_training/hotkeys.json',
  macro_dir = 'plugins/vsav_training/macro/recordings/',
  image_dir = 'plugins/vsav_training/images/',
}

return {
  TRAINING_SETTINGS
}