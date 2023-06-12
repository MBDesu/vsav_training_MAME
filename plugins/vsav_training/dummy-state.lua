local input = require './vsav_training/utils/input-util'
local m = require './vsav_training/utils/memory-util'
local mem_map = require './vsav_training/constants/memory-map'
local player_data = require './vsav_training/constants/player-data'

local p1_base_addr = mem_map.player_data.p1_base_addr
local p2_base_addr = mem_map.player_data.p2_base_addr

local player_state = {
  {
    is_hurt = false,
    was_hurt = false,
    last_hurt = 0,
    last_holding = 'N',
    last_facing = 'right',
  },
  {
    is_hurt = false,
    was_hurt = false,
    last_hurt = 0,
    last_holding = 'N',
    last_facing = 'left',
  }
}

local function set_player_health(player_base_addr, value)
  m.wwu(player_base_addr + mem_map.player_data.red_health.offset, value)
  m.wwu(player_base_addr + mem_map.player_data.white_health.offset, value)
end

local function set_player_meter(player_base_addr, value)
  m.wbu(player_base_addr + mem_map.player_data.meter_stock.offset, value or 0x63)
end

local function set_player_hold_direction()
  local new_dir = TRAINING_SETTINGS.DUMMY_SETTINGS.p2_hold_direction
  local old_dir = player_state[2].last_holding

  if new_dir == 'N' and old_dir ~= 'N' then
    input.deactivate_inputs({'UP', 'DOWN', 'LEFT', 'RIGHT'});
    player_state[2].last_holding = 'N'
    return
  end

  if new_dir ~= old_dir then
    input.deactivate_inputs({'UP', 'DOWN', 'LEFT', 'RIGHT'});
    local inputs = {}
    if new_dir:find('D') then inputs[#inputs + 1] = 'DOWN' end
    if new_dir:find('U') then inputs[#inputs + 1] = 'UP' end
    if new_dir:find('B') then
      if player_state[2].facing == 'left' then
        inputs[#inputs + 1] = 'BACK'
      else
        inputs[#inputs + 1] = 'FORWARD'
      end
    end
    if new_dir:find('F') then
      if player_state[2].facing == 'left' then
        inputs[#inputs + 1] = 'FORWARD'
      else
        inputs[#inputs + 1] = 'BACK'
      end
    end
    player_state[2].last_holding = new_dir
    input.activate_inputs(inputs)
  end

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

local function update_player_facing()
  local p1_face = m.rbu(p1_base_addr + mem_map.player_data.flip_x)
  local p2_face = m.rbu(p2_base_addr + mem_map.player_data.flip_x)
  if p1_face == 0x1 then player_state[1].last_facing = 'right' else player_state[1].last_facing = 'left' end
  if p2_face == 0x1 then player_state[2].last_facing = 'right' else player_state[2].last_facing = 'left' end

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
    m.wbu(p1_base_addr + mem_map.player_data.remaining_taunts.offset, 0x0)
    m.wbu(p2_base_addr + mem_map.player_data.remaining_taunts.offset, 0x0)
  end
end

local function reset_dummy_state()
  for i = 1, 2 do
    player_state[i].is_hurt = false
    player_state[i].was_hurt = false
    player_state[i].last_hurt = 0
    player_state[i].last_holding = 'N'
  end
end

local function update_player_parameters()
  update_player_facing()
  update_player_health()
  update_player_meter()
  set_player_hold_direction()
  disable_taunts()
end

return {
  ['reset_dummy_state'] = reset_dummy_state,
  -- dummy_state doesn't register its own frame done due to dependency on game_state
  ['register_frame_done'] = update_player_parameters
}