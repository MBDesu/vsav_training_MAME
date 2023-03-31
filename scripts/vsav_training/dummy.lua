local mem_map = require './scripts/vsav_training/constants/memory-map'
local m = require './scripts/vsav_training/utils/memory-util'
local game_state = require './scripts/vsav_training/game-state'

local dummy_base_addr = mem_map.player_data.p2_base_addr

local function set_dummy_health(value)
  m.wwu(dummy_base_addr + mem_map.player_data.red_health.offset, value)
  m.wwu(dummy_base_addr + mem_map.player_data.white_health.offset, value)
end

local function set_dummy_parameters()
  if game_state.match_has_begun() then
    -- if SETTINGS.DUMMY_SETTINGS.infinite_health then set_dummy_health(0x120) end
    set_dummy_health(SETTINGS.DUMMY_SETTINGS.max_health)
  end
end

return {
  ['registerFrameDone'] = set_dummy_parameters
}