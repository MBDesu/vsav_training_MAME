local exports = {
  name = 'vsav_training',
  version = '0.0.1',
  description = 'Training mode for Vampire Savior',
  author = { name = 'MBDesu' }
}

----------------------------- globals start
require './vsav_training/utils/lua-util'
require './vsav_training/settings'
require './vsav_training/constants/data-types'

-- singleton service
---@type game_state
GAME_STATE = nil

-- singleton service
---@type dummy_state
DUMMY_STATE = nil

-- singleton service
---@type mem_watch_service
MEM_WATCH_SERVICE = nil
----------------------------- globals end

local vsav_training = exports

function vsav_training.set_folder(path)
  vsav_training.path = path
end

function vsav_training.startplugin()
  local hitbox_viewer
  local stage_select
  emu.register_before_load_settings(function()
    local file_util = require './vsav_training/utils/file-util'
    file_util.parse_training_settings()
    stage_select = require './vsav_training/stage-select'
  end)
  emu.register_prestart(function()
    if not GAME_STATE then
      GAME_STATE = require './vsav_training/services/game-state'
      MEM_WATCH_SERVICE = require './vsav_training/services/mem-watch-service'
      require './vsav_training/input-viewer'
      hitbox_viewer = require './vsav_training/hitbox-viewer'
      DUMMY_STATE = require './vsav_training/services/dummy-state'
      hitbox_viewer.start()
      require('./vsav_training/menu').register_prestart()
      require('./vsav_training/debug-workspace')
    end
  end)
  emu.register_frame(function()
    if GAME_STATE and GAME_STATE.match_has_begun() then
      hitbox_viewer.register_frame()
    else
      stage_select.select_stage()
    end
  end)
  emu.register_frame_done(function()
    if GAME_STATE and GAME_STATE.match_has_begun() then
      DUMMY_STATE.register_frame_done()
      hitbox_viewer.register_frame_done()
      GAME_STATE.register_frame_done()
    end
  end)
end

return vsav_training