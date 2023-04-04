-- imports and config start
require './scripts/vsav_training/utils/lua-util'
require './scripts/vsav_training/settings'

local file_util = require './scripts/vsav_training/utils/file-util'
file_util.parse_training_settings()

require './scripts/vsav_training/menu'

local game_state = require './scripts/vsav_training/game-state'
local dummy = require './scripts/vsav_training/dummy-state'
local hitbox_viewer = require './scripts/vsav_training/hitbox-viewer'
local stage_select = require './scripts/vsav_training/stage-select'

hitbox_viewer.start()
-- imports and config end

-- scratchpad start
-- for k, v in pairs(manager.machine.ioport.types) do
--   print(k, v.name)
--   print(k, v.type)
--   print(k, v.group)
--   print(k, v.player)
--   print(k, v.token)
--   print(k, v.name)
--   print('===================')
-- end
-- scratchpad end
emu.register_frame(function()
  if game_state.match_has_begun() then
    hitbox_viewer.registerFrame()
  else
    stage_select.select_stage()
  end
end)
emu.register_frame_done(function()
  if game_state.match_has_begun() then
    dummy.registerFrameDone()
    hitbox_viewer.registerFrameDone()
    game_state.registerFrameDone()
  end
end)