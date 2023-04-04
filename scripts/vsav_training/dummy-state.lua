local mem_map = require './scripts/vsav_training/constants/memory-map'
local player_data = require './scripts/vsav_training/constants/player-data'
local m = require './scripts/vsav_training/utils/memory-util'

local p1_base_addr = mem_map.player_data.p1_base_addr
local p2_base_addr = mem_map.player_data.p2_base_addr

local player_state = {
  {
    is_hurt = false,
    was_hurt = false,
    last_hurt = 0,
  },
  {
    is_hurt = false,
    was_hurt = false,
    last_hurt = 0,
  }
}

local function set_player_health(player_base_addr, value)
  m.wwu(player_base_addr + mem_map.player_data.red_health.offset, value)
  m.wwu(player_base_addr + mem_map.player_data.white_health.offset, value)
end

local function set_player_meter(player_base_addr, value)
  m.wbu(player_base_addr + mem_map.player_data.meter_stock.offset, value or 0x63)
end

local function update_hurt_timer(player_num, player_base_addr)
  local player_status = player_state[player_num]
  local status = m.rbu(player_base_addr + mem_map.player_data.status_1.offset)
  local is_hurt = player_data.status_1_table[status] == 'Hurt or Block'
  player_status.is_hurt = is_hurt
  if is_hurt and not player_status.was_hurt then
    player_status.was_hurt = true
  end
  if player_status.was_hurt and not is_hurt then
    player_status.last_hurt = manager.machine.screens[':screen']:frame_number()
    player_status.was_hurt = false
  end
end

local function update_player_health()
  update_hurt_timer(1, p1_base_addr)
  update_hurt_timer(2, p2_base_addr)
  if TRAINING_SETTINGS.DUMMY_SETTINGS.p1_infinite_health then
    set_player_health(p1_base_addr, 0x120)
  elseif player_state[1].last_hurt > 0 and (TRAINING_SETTINGS.DUMMY_SETTINGS.p1_delay_to_refill * 60) + player_state[1].last_hurt <= manager.machine.screens[':screen']:frame_number() then
    set_player_health(p1_base_addr, TRAINING_SETTINGS.DUMMY_SETTINGS.p1_max_health)
    player_state[1].last_hurt = 0
  end
  if TRAINING_SETTINGS.DUMMY_SETTINGS.p2_infinite_health then
    set_player_health(p2_base_addr, 0x120)
  elseif player_state[2].last_hurt > 0 and (TRAINING_SETTINGS.DUMMY_SETTINGS.p2_delay_to_refill * 60) + player_state[2].last_hurt <= manager.machine.screens[':screen']:frame_number() then
    set_player_health(p2_base_addr, TRAINING_SETTINGS.DUMMY_SETTINGS.p2_max_health)
    player_state[2].last_hurt = 0
  end
end

local function update_player_meter()
  if TRAINING_SETTINGS.DUMMY_SETTINGS.p1_infinite_meter then
    set_player_meter(p1_base_addr)
  end
  if TRAINING_SETTINGS.DUMMY_SETTINGS.p2_infinite_meter then
    set_player_meter(p2_base_addr)
  end
end

local function disable_taunts()
  if TRAINING_SETTINGS.TRAINING_OPTIONS.disable_taunts then
    m.wbu(mem_map.player_data.p1_base_addr + mem_map.player_data.remaining_taunts.offset, 0x0)
    m.wbu(mem_map.player_data.p2_base_addr + mem_map.player_data.remaining_taunts.offset, 0x0)
  end
end

local function reset_dummy_state()
  for i = 1, 2 do
    player_state[i].is_hurt = false
    player_state[i].was_hurt = false
    player_state[i].last_hurt = 0
  end
end

local function update_player_parameters()
  update_player_health()
  update_player_meter()
  disable_taunts()
end

return {
  ['reset_dummy_state'] = reset_dummy_state,
  -- dummy_state doesn't register its own frame done due to dependency on game_state
  ['registerFrameDone'] = update_player_parameters
}