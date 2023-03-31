require './scripts/vsav_training/settings'
require './scripts/vsav_training/menu'
require './scripts/vsav_training/utils/lua-util'
local dummy = require './scripts/vsav_training/dummy'
local hitboxViewer = require './scripts/vsav_training/hitbox-viewer'

hitboxViewer.start()
emu.register_start(function()

end)
emu.register_frame(function()
  hitboxViewer.registerFrame()
end)
emu.register_frame_done(function()
  dummy.registerFrameDone()
  hitboxViewer.registerFrameDone()
end)