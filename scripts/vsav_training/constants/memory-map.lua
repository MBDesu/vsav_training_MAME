require './scripts/vsav_training/constants/data-types'

local global_settings = {
  base_addr = 0xFF8000,
  coin_and_start_input = {
    offset = 0x60,
    size = DWORD
  },
  current_stage = {
    offset = 0x100,
    size = WORD
  },
  game_speed = {
    offset = 0x116,
    size = BYTE
  },
  screen_left = {
    offset = 0x290,
    size = WORD
  }
}

local player_data = {
  p1_base_addr = 0xFF8400,
  p2_base_addr = 0xFF8800,
  char_sel_cursor_pos = {
    offset = 0x03,
    size = BYTE
  },
  status_1 = {
    offset = 0x05,
    size = BYTE
  },
  status_2 = {
    offset = 0x06,
    size = BYTE
  },
  flip_x = {
    offset = 0x0B,
    size = BYTE
  },
  red_health = {
    offset = 0x50,
    size = WORD
  },
  white_health = {
    offset = 0x52,
    size = WORD
  },
  head_hurtbox_ptr = {
    offset = 0x80,
    size = DWORD
  },
  body_hurtbox_ptr = {
    offset = 0x84,
    size = DWORD
  },
  foot_hurtbox_ptr = {
    offset = 0x88,
    size = DWORD
  },
  attack_box_ptr = {
    offset = 0x8C,
    size = DWORD
  },
  push_box_ptr = {
    offset = 0x90,
    size = DWORD
  },
  head_hurtbox_id = {
    offset = 0x94,
    size = BYTE
  },
  body_hurtbox_id = {
    offset = 0x95,
    size = BYTE
  },
  foot_hurtbox_id = {
    offset = 0x96,
    size = BYTE
  },
  push_box_id = {
    offset = 0x97,
    size = BYTE
  },
  animation_ptr = {
    offset = 0x1C,
    size = DWORD
  }
}

local projectile_data = {
  projectiles_base_addr = 0xFF9400,
}

return {
  ['global_settings'] = global_settings,
  ['player_data'] = player_data,
  ['projectile_data'] = projectile_data,
}