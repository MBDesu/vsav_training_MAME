local mem_map = require './scripts/vsav_training/constants/memory-map'
local m = require './scripts/vsav_training/utils/memory-util'

local dummy_base_addr = mem_map.player_battle_data.p2_base_addr

local function set_dummy_parameters()
  if SETTINGS.DUMMY_SETTINGS.infinite_health then
    m.wwu(dummy_base_addr + mem_map.player_battle_data.red_health.offset, 0x120)
    m.wwu(dummy_base_addr + mem_map.player_battle_data.white_health.offset, 0x120)
  end
end

return {
  ['registerFrameDone'] = set_dummy_parameters
}