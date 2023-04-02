-- imports and config start
require './scripts/vsav_training/utils/lua-util'
require './scripts/vsav_training/settings'

local file_util = require './scripts/vsav_training/utils/file-util'
file_util.parse_training_settings()
require './scripts/vsav_training/menu'

local game_state = require './scripts/vsav_training/game-state'
local dummy = require './scripts/vsav_training/dummy-state'
local hitbox_viewer = require './scripts/vsav_training/hitbox-viewer'
-- imports and config end

hitbox_viewer.start()
emu.register_frame(function()
  if game_state.match_has_begun() then
    hitbox_viewer.registerFrame()
  end
end)
emu.register_frame_done(function()
  if game_state.match_has_begun() then
    dummy.registerFrameDone()
    hitbox_viewer.registerFrameDone()
    game_state.registerFrameDone()
  end
end)