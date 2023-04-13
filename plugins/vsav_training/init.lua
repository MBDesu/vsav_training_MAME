local exports = {
  name = 'vsav_training',
  version = '0.0.1',
  description = 'Training mode for Vampire Savior',
  author = { name = 'MBDesu' }
}

require './vsav_training/utils/lua-util'
require './vsav_training/settings'
require './vsav_training/constants/data-types'

local vsav_training = exports

function vsav_training.set_folder(path)
  vsav_training.path = path
end

function vsav_training.startplugin()
  local game_state
  local dummy
  local hitbox_viewer
  local stage_select
  emu.register_before_load_settings(function()
    local file_util = require './vsav_training/utils/file-util'
    file_util.parse_training_settings()
    stage_select = require './vsav_training/stage-select'
  end)
  emu.register_prestart(function()
    if not game_state then
      game_state = require './vsav_training/game-state'
      require './vsav_training/input-viewer'
      hitbox_viewer = require './vsav_training/hitbox-viewer'
      dummy = require './vsav_training/dummy-state'
      hitbox_viewer.start()
      require('./vsav_training/menu').register_prestart()
    end
  end)
  emu.register_frame(function()
    if game_state and game_state.match_has_begun() then
      hitbox_viewer.register_frame()
    else
      stage_select.select_stage()
    end
  end)
  emu.register_frame_done(function()
    if game_state and game_state.match_has_begun() then
      dummy.register_frame_done()
      hitbox_viewer.register_frame_done()
      game_state.register_frame_done()
    end
  end)
end

return vsav_training