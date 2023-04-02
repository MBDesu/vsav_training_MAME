require './scripts/vsav_training/settings'
require './scripts/vsav_training/menu'
require './scripts/vsav_training/utils/lua-util'
local game_state = require './scripts/vsav_training/game-state'
local dummy = require './scripts/vsav_training/dummy-state'
local hitboxViewer = require './scripts/vsav_training/hitbox-viewer'

hitboxViewer.start()
emu.register_frame(function()
  if game_state.match_has_begun() then
    hitboxViewer.registerFrame()
  end
end)
emu.register_frame_done(function()
  if game_state.match_has_begun() then
    dummy.registerFrameDone()
    hitboxViewer.registerFrameDone()
  end
end)