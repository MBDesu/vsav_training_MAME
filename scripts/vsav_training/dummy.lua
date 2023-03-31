local mem_map = require './scripts/vsav_trainer/constants/memroy-map'
local m = require './scripts/vsav_trainer/utils/memory-util'

local dummy_base_addr = m.player_battle_data.p2_base_addr

local function set_dummy_parameters()
  if SETTINGS.DUMMY_SETTINGS.infinite_health then
    m.wbu(dummy_base_addr + mem_map.player_battle_data.red_health, 0xFF)
    m.wbu(dummy_base_addr + mem_map.player_battle_data.white_health, 0xFF)
  end
end

return {
  ['registerFrameDone'] = set_dummy_parameters
}