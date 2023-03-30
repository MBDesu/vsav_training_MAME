require './scripts/vsav_training/constants/data-types'

local global_settings = {
  base_addr = 0xFF8000,
  coin_and_start_input = {
    offset = 0x60,
    size = DWORD
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

local player_battle_data = {
  p1_base_addr = 0xFF8400,
  p2_base_addr = 0xFF8800,
  status_1 = {
    offset = 0x05,
    size = BYTE
  },
  status_2 = {
    offset = 0x06,
    size = BYTE
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
  ['player_battle_data'] = player_battle_data,
  ['projectile_data'] = projectile_data,
}