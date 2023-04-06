
local status_1_table = {}
local status_2_table = {}
local jump_ground_roll_type_table = {}
local facing_direction_or_flip_table = {}

do
  status_1_table[0x00] = 'Normal'
  status_1_table[0x02] = 'Hurt or Block'
  status_1_table[0x04] = 'Throw'
  status_1_table[0x06] = 'Be Thrown'
  status_1_table[0x08] = 'Win Pose'
  status_1_table[0x0A] = 'Time Up Pose'
  status_1_table[0x0C] = 'Trigger Opponent Win Pose'
  status_1_table[0x0E] = 'Intro'
  status_1_table[0x10] = 'Cursed'
  status_1_table[0x12] = 'Time Up Win'
  status_2_table[0x00] = 'Normal'
  status_2_table[0x02] = 'Stand/Crouch Transition'
  status_2_table[0x04] = 'Walk'
  status_2_table[0x06] = 'Jump'
  status_2_table[0x08] = 'Intro Animation'
  status_2_table[0x0A] = 'Ground Normal Attack'
  status_2_table[0x0C] = 'Proximity Block'
  status_2_table[0x0E] = 'Special Attack'
  status_2_table[0x10] = 'ES Attack'
  status_2_table[0x12] = 'EX Attack'
  status_2_table[0x14] = 'Dashing'
  status_2_table[0x16] = 'Dark Force Activate'
  status_2_table[0x18] = 'Dark Force Activate with Flight'
  status_2_table[0x1A] = 'Dark Force Deactivate'
  status_2_table[0x1C] = 'Dark Force with Stingray'
  status_2_table[0x1E] = 'Victor Dark Force Grap - Whiff'
  status_2_table[0x20] = 'Victor Dark Force Grab - Animation 1'
  status_2_table[0x22] = 'Victor Dark Force Grab - Animation 2'
  status_2_table[0x24] = 'Victor Dark Force Grab - Animation 3'
  status_2_table[0x26] = 'Victor Dark Force Grab - Animation 4'
  status_2_table[0x28] = 'Grapple Mash Startup (not teched)'
  status_2_table[0x2A] = 'Grapple Mash'
  status_2_table[0x2C] = 'Grapple Mash Recovery'
  jump_ground_roll_type_table[0x00] = 'Neutral'
  jump_ground_roll_type_table[0x01] = 'Toward'
  jump_ground_roll_type_table[0xFF] = 'Away'
  facing_direction_or_flip_table[0x00] = 'Left'
  facing_direction_or_flip_table[0x01] = 'Right'
end

return {
  ['status_1_table'] = status_1_table,
  ['status_2_table'] = status_2_table,
  ['jump_ground_roll_type_table'] = jump_ground_roll_type_table,
  ['facing_direction_or_flip_table'] = facing_direction_or_flip_table,
}