---this script is meant to be a singleton; its single instance is instantiated
---in [`init.lua`](../init.lua)
local input = require './vsav_training/utils/input-util'
local m = require './vsav_training/utils/memory-util'
local mem_map = require './vsav_training/constants/memory-map'
local player_data = require './vsav_training/constants/player-data'

local p1_base_addr = mem_map.player_data.p1_base_addr
local p2_base_addr = mem_map.player_data.p2_base_addr

-- TODO: define these aliases in typedef
---@alias player_status { is_hurt: boolean, was_hurt: boolean, last_hurt: number, can_gc: boolean, poison_gas_timer: number, hitstop_timer: number, pushback_timer: number, }
---@alias player_state table<player_status>

local player_state = {
  {
    is_hurt   = false,
    was_hurt  = false,
    last_hurt = 0,
    can_gc    = false,
    poison_gas_timer = 0,
    hitstop_timer = 0,
    pushback_timer = 0,
    last_holding = 'N',
    last_facing = 'right',
  },
  {
    is_hurt   = false,
    was_hurt  = false,
    last_hurt = 0,
    can_gc    = false,
    poison_gas_timer = 0,
    hitstop_timer = 0,
    pushback_timer = 0,
    last_holding = 'N',
    last_facing = 'left',
  }
}

local function update_player_state()
  player_state[1].can_gc = m.rbu(mem_map.player_data.p1_base_addr + mem_map.player_data.gc_timer.offset) > 0
  player_state[2].can_gc = m.rbu(mem_map.player_data.p2_base_addr + mem_map.player_data.gc_timer.offset) > 0
  player_state[1].poison_gas_timer = m.rbu(mem_map.player_data.p1_base_addr + mem_map.player_data.poison_gas_timer.offset)
  player_state[2].poison_gas_timer = m.rbu(mem_map.player_data.p2_base_addr + mem_map.player_data.poison_gas_timer.offset)
  player_state[1].hitstop_timer = m.rbu(mem_map.player_data.p1_base_addr + mem_map.player_data.hitstop_timer.offset)
  player_state[2].hitstop_timer = m.rbu(mem_map.player_data.p2_base_addr + mem_map.player_data.hitstop_timer.offset)
  player_state[1].pushback_timer = m.rbu(mem_map.player_data.p1_base_addr + mem_map.player_data.hitstop_timer.offset)
  player_state[2].pushback_timer = m.rbu(mem_map.player_data.p2_base_addr + mem_map.player_data.hitstop_timer.offset)
end

local function set_player_health(player_base_addr, value)
  m.wwu(player_base_addr + mem_map.player_data.red_health.offset, value)
  m.wwu(player_base_addr + mem_map.player_data.white_health.offset, value)
end

local function set_player_meter(player_base_addr, value)
  m.wbu(player_base_addr + mem_map.player_data.meter_stock.offset, value or 0x63)
end

-- TODO: refactor
local function update_player_hold_direction(facing_changed)
  local new_dir = TRAINING_SETTINGS.DUMMY_SETTINGS.p2_hold_direction
  local old_dir = player_state[2].last_holding

  if new_dir == 'N' and old_dir ~= 'N' then
    input.deactivate_inputs({ 'UP', 'DOWN', 'LEFT', 'RIGHT' });
    player_state[2].last_holding = 'N'
    return
  end

  if new_dir ~= old_dir then
    input.deactivate_inputs({ 'UP', 'DOWN', 'LEFT', 'RIGHT' });
    local inputs = {}
    if new_dir:find('D') then inputs[#inputs + 1] = 'DOWN' end
    if new_dir:find('U') then inputs[#inputs + 1] = 'UP' end
    if new_dir:find('B') then
      if player_state[2].last_facing == 'left' then
        inputs[#inputs + 1] = 'RIGHT'
      else
        inputs[#inputs + 1] = 'LEFT'
      end
    end
    if new_dir:find('F') then
      if player_state[2].last_facing == 'left' then
        inputs[#inputs + 1] = 'LEFT'
      else
        inputs[#inputs + 1] = 'RIGHT'
      end
    end
    player_state[2].last_holding = new_dir
    input.activate_inputs(inputs)
  elseif facing_changed then
    if player_state[2].last_holding:find('B') then
      if player_state[2].last_facing == 'left' then
        input.deactivate_inputs({ 'LEFT' })
        input.activate_inputs({ 'RIGHT' })
      else
        input.deactivate_inputs({ 'RIGHT' })
        input.activate_inputs({ 'LEFT' })
      end
    elseif player_state[2].last_holding:find('F') then
      if player_state[2].last_facing == 'left' then
        input.deactivate_inputs({ 'RIGHT' })
        input.activate_inputs({ 'LEFT' })
      else
        input.deactivate_inputs({ 'LEFT' })
        input.activate_inputs({ 'RIGHT' })
      end
    end
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
  local p1_face = m.rbu(p1_base_addr + mem_map.player_data.flip_x.offset)
  local p2_face = m.rbu(p2_base_addr + mem_map.player_data.flip_x.offset)

  local p1_new_facing = player_state[1].last_facing
  local p2_new_facing = player_state[2].last_facing

  if p1_face == 0x1 then
    p1_new_facing = 'right'
  elseif p1_face == 0x0 then
    p1_new_facing = 'left'
  end
  if p2_face == 0x1 then
    p2_new_facing = 'right'
  elseif p2_face == 0x0 then
    p2_new_facing = 'left'
  end

  if p1_new_facing ~= player_state[1].last_facing then
    player_state[1].last_facing = p1_new_facing
  end
  if p2_new_facing ~= player_state[2].last_facing then
    player_state[2].last_facing = p2_new_facing
    update_player_hold_direction(true)
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
    player_state[i].is_hurt          = false
    player_state[i].was_hurt         = false
    player_state[i].last_hurt        = 0
    player_state[i].can_gc           = false
    player_state[i].poison_gas_timer = 0
    player_state[i].hitstop_timer    = 0
    player_state[i].pushback_timer   = 0
  end
end

local function update_player_parameters()
  if GAME_STATE and GAME_STATE.match_has_begun() then
    update_player_facing()
    update_player_hold_direction()
    update_player_health()
    update_player_meter()
    update_player_state()
    disable_taunts()
  end
end

return {
  ['reset_dummy_state'] = reset_dummy_state,
  -- dummy_state doesn't register its own frame done due to dependency on game_state
  -- ['register_frame'] = function()
  --   if  m.rbu(0xFF8575) == 0 and
  --       m.rbu(0xFF8571) == 0 and
  --       m.rbu(0xFF8519) == 0 and
  --       (m.rwu(0xFF8511) == 0 or m.rwu(0xFF8511) == m.rbu(0xFF8510)) and
  --       m.rdu(0xFF8404) == 0x02020400 then
  --     print('r-frame', m.rbu(mem_map.global_settings.base_addr + mem_map.global_settings.drawn_frame_counter.offset));
  --   end
  -- end,
  ['register_frame_done'] = update_player_parameters,
  ['player_state'] = player_state,
}