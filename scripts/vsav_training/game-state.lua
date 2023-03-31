local mem_map = require './scripts/vsav_training/constants/memory-map'
local m = require './scripts/vsav_training/utils/memory-util'

local function match_has_begun()
  -- TODO: map these offsets
  return (m.rdu(0xFF8004) == 0x40000 and m.rdu(0xFF8008) == 0x40000) or (m.rwu(0xFF8008) == 0x2 and m.rwu(0xFF800A) > 0)
end

local function set_game_state_parameters()
  
end

return {
  ['match_has_begun'] = match_has_begun
}