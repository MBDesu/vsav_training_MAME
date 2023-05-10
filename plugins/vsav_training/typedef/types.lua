---@meta _

---Service that exposes information about the game state.
---@class game_state
local game_state = {}
---Returns a boolean indicating whether the battle scene is active
---@return boolean
function game_state.match_has_begun() end
---Returns the game state to character select.
function game_state.return_to_character_select() end
---Should only be called from `init.lua`
function game_state.register_frame_done() end
function game_state.hide_meters() end
function game_state.hide_life_bars() end
function game_state.hide_background() end

---Service that exposes information about player/dummy state.
---@class dummy_state
---@field player_state player_state
local dummy_state = {}
---Resets the dummy state to initial values.
function dummy_state.reset_dummy_state() end
---Should only be called from `init.lua`
function dummy_state.register_frame_done() end
---Should only be called from `init.lua`
function dummy_state.register_frame() end

---Service that allows you to register memory regions for watching and execute
---callback functions when they are accessed.
---@class mem_watch_service
local mem_watch_service = {}
---Registers a memory watcher. Callback is passed the offset of the accessed
---memory, the data read, and the data mask. If the callback returns a number,
---the data read is overwritten with that value.
---
---Note that single bytes are actually read as words; this means that in order
---to modify a single byte, you should return `value | data & 0xFF`.
---@param name string
---@param start_addr number
---@param size number
---@param callback fun(offset?: number, data?: number, mask?: number): number?
---@return passthrough_handler
function mem_watch_service.watch_reads(name, start_addr, size, callback) end
---Registers a memory watcher. Callback is passed the offset of the accessed
---memory, the data read, and the data mask. If the callback returns a number,
---the data read is overwritten with that value.
---
---Note that single bytes are actually read as words; this means that in order
---to modify a single byte, you should return `value | data & 0xFF`.
---@param name string
---@param start_addr number
---@param size number
---@param callback fun(offset?: number, data?: number, mask?: number): number?
---@return passthrough_handler
function mem_watch_service.watch_writes(name, start_addr, size, callback) end

return game_state, dummy_state, mem_watch_service