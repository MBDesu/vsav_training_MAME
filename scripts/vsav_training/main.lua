require './scripts/vsav_training/lua-util'

-- globals
CPU = require './scripts/vsav_training/m68k-util'
MEMORY_MAP = require './scripts/vsav_training/constants/memory-map'
MEM = require './scripts/vsav_training/memory-util'
PLAYER_STATUS = require './scripts/vsav_training/constants/player-status'
GUI = manager.machine.screens[':screen']
SYSTEM = manager.machine.system
local m68k = require './scripts/vsav_training/constants/m68k'
local hitboxViewer = require './scripts/vsav_training/hitbox-viewer'

hitboxViewer.start()
-- print('C set? ' .. tostring(CPU.is_flag_set(m68k.ccr_flag.C)))
-- print('V set? ' .. tostring(CPU.is_flag_set(m68k.ccr_flag.V)))
-- print('Z set? ' .. tostring(CPU.is_flag_set(m68k.ccr_flag.Z)))
-- print('N set? ' .. tostring(CPU.is_flag_set(m68k.ccr_flag.N)))
-- print('X set? ' .. tostring(CPU.is_flag_set(m68k.ccr_flag.X)))
emu.register_frame(function()
  hitboxViewer.registerFrame()
end)
emu.register_frame_done(function()
  hitboxViewer.registerFrameDone()
end)