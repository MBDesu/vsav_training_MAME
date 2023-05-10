---this script is meant to be a singleton; its single instance is instantiated
---in [`init.lua`](../init.lua)
local mem_map = require './vsav_training/constants/memory-map'
local m = require './vsav_training/utils/memory-util'

local function match_has_begun()
  -- TODO: map these offsets
  return (m.rdu(0xFF8004) == 0x40000 and m.rdu(0xFF8008) == 0x40000) or (m.rwu(0xFF8008) == 0x2 and m.rwu(0xFF800A) > 0)
end

-- turbo 1, 2, and 3 correspond to menu values 1, 2, and 3; however, they
-- correspond to game speed values of 6, 7, and 8, so we set both
local function set_game_speed(speed)
  local game_speed = 0
  if speed ~= 0 then game_speed = speed + 5 end
  m.wbu(mem_map.global_settings.base_addr + mem_map.global_settings.game_speed_menu_setting.offset, speed)
  m.wbu(mem_map.global_settings.base_addr + mem_map.global_settings.game_speed.offset, game_speed)
end

local function set_time(value)
  m.wbu(mem_map.global_settings.base_addr + mem_map.global_settings.game_clock.offset, value or 0x63)
end

local function hide_life_bars()
  if TRAINING_SETTINGS.TRAINING_OPTIONS.hide_life_bars then
    m.wwu(mem_map.hud_settings.hud_base_addr + mem_map.hud_settings.lifebar_display.offset, 0)
  elseif m.rwu(mem_map.hud_settings.hud_base_addr + mem_map.hud_settings.lifebar_display.offset) == 0 then
    m.wwu(mem_map.hud_settings.hud_base_addr + mem_map.hud_settings.lifebar_display.offset, 0x0101)
  end
end

local function hide_meters()
  if TRAINING_SETTINGS.TRAINING_OPTIONS.hide_meters then
    m.wwu(mem_map.hud_settings.hud_base_addr + mem_map.hud_settings.meter_display.offset, 0)
  elseif m.rwu(mem_map.hud_settings.hud_base_addr + mem_map.hud_settings.meter_display.offset) == 0 then
    m.wwu(mem_map.hud_settings.hud_base_addr + mem_map.hud_settings.meter_display.offset, 0x0101)
  end
end

local function hide_background()
  if TRAINING_SETTINGS.TRAINING_OPTIONS.hide_background then
    m.wbu(mem_map.global_settings.base_addr + mem_map.global_settings.background_layer.offset, 0)
  elseif m.rbu(mem_map.global_settings.base_addr + mem_map.global_settings.background_layer.offset) ~= 0xE then
    m.wbu(mem_map.global_settings.base_addr + mem_map.global_settings.background_layer.offset, 0xE)
  end
end

local function update_game_state_parameters()
  if match_has_begun() then
    set_game_speed(TRAINING_SETTINGS.GAME_SETTINGS.game_speed)
    if TRAINING_SETTINGS.TRAINING_OPTIONS.infinite_time then
      set_time()
    end
    hide_background()
    hide_meters()
    hide_life_bars()
  end
end

local function return_to_character_select()
  if match_has_begun() then
    -- TODO: map this offset
    m.wbu(0xFF8005, 0x0C)
  end
end

return {
  ['match_has_begun'] = match_has_begun,
  ['return_to_character_select'] = return_to_character_select,
  ['register_frame_done'] = update_game_state_parameters,
  ['hide_meters'] = hide_meters,
  ['hide_life_bars'] = hide_life_bars,
  ['hide_background'] = hide_background,
}