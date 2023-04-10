-- imports and config start
require './scripts/vsav_training/utils/lua-util'
require './scripts/vsav_training/settings'
require './scripts/vsav_training/input-viewer'

local file_util = require './scripts/vsav_training/utils/file-util'
file_util.parse_training_settings()

require './scripts/vsav_training/menu'

local game_state = require './scripts/vsav_training/game-state'
local dummy = require './scripts/vsav_training/dummy-state'
local hitbox_viewer = require './scripts/vsav_training/hitbox-viewer'
local stage_select = require './scripts/vsav_training/stage-select'

hitbox_viewer.start()
-- imports and config end
emu.register_frame(function()
  if game_state.match_has_begun() then
    hitbox_viewer.register_frame()
  else
    stage_select.select_stage()
  end
end)
emu.register_frame_done(function()
  if game_state.match_has_begun() then
    dummy.register_frame_done()
    hitbox_viewer.register_frame_done()
    game_state.register_frame_done()
  end
end)