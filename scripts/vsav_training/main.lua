require './scripts/vsav_training/settings'
require './scripts/vsav_training/menu'
require './scripts/vsav_training/utils/lua-util'
local game_state = require './scripts/vsav_training/game-state'
local dummy = require './scripts/vsav_training/dummy-state'
local hitbox_viewer = require './scripts/vsav_training/hitbox-viewer'

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