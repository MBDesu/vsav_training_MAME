local mem_map = require './scripts/vsav_training/constants/memory-map'
local m = require './scripts/vsav_training/utils/memory-util'

local function match_has_begun()
  -- TODO: map these offsets
  return (m.rdu(0xFF8004) == 0x40000 and m.rdu(0xFF8008) == 0x40000) or (m.rwu(0xFF8008) == 0x2 and m.rwu(0xFF800A) > 0)
end

local function set_time(value)
  m.wbu(mem_map.global_settings.base_addr + mem_map.global_settings.game_clock.offset, value or 0x63)
end

local function update_game_state_parameters()
  if match_has_begun() then
    if SETTINGS.TRAINING_OPTIONS.infinite_time then
      set_time()
    end
  end
end

return {
  ['match_has_begun'] = match_has_begun,
  ['registerFrameDone'] = update_game_state_parameters
}