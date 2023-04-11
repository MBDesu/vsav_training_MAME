TRAINING_SETTINGS = {
  DUMMY_SETTINGS = {
    p1_infinite_health = true,
    p1_infinite_meter = true,
    p1_max_health = 288,
    p1_delay_to_refill = 0,
    p2_infinite_health = true,
    p2_infinite_meter = true,
    p2_max_health = 288,
    p2_delay_to_refill = 0,
  },
  TRAINING_OPTIONS = {
    show_hitboxes = true,
    fill_hitboxes = true,
    blank_screen = false,
    infinite_time = true,
    disable_taunts = false,
  },
  GAME_SETTINGS = {
    game_speed = 3,
  },
}

SCRIPT_SETTINGS = {
  training_settings_file = 'plugins/vsav_training/training_settings.json',
  hotkeys_settings_file = 'plugins/vsav_training/hotkeys.json',
  macro_dir = 'plugins/vsav_training/macro/recordings/',
}

return {
  TRAINING_SETTINGS
}