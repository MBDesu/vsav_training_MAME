require './scripts/vsav_training/constants/function-data'
local character_data = require './scripts/vsav_training/constants/character-data'
local mem_map = require './scripts/vsav_training/constants/memory-map'
local stage_data = require './scripts/vsav_training/constants/stage-data'
local cpu = require './scripts/vsav_training/utils/m68k-util'
local m = require './scripts/vsav_training/utils/memory-util'

local selected_stage = nil
local was_coin_pressed_last_frame = false
local stage_bp = 0

local function resolve_char_id_to_stage_value(char_id)
  if     char_id == character_data.CHARACTER_ID['Bulleta']   then return stage_data['STAGE_VALUES'].WarAgony
  elseif char_id == character_data.CHARACTER_ID['Demitri']   then return stage_data['STAGE_VALUES'].FeastOfTheDamned
  elseif char_id == character_data.CHARACTER_ID['Gallon']    then return stage_data['STAGE_VALUES'].ConcreteCave
  elseif char_id == character_data.CHARACTER_ID['Victor']    then return stage_data['STAGE_VALUES'].ForeverTorment
  elseif char_id == character_data.CHARACTER_ID['Zabel']     then return stage_data['STAGE_VALUES'].IronHorseIronTerror
  elseif char_id == character_data.CHARACTER_ID['Morrigan']  then return stage_data['STAGE_VALUES'].DesertedChateau
  elseif char_id == character_data.CHARACTER_ID['Anakaris']  then return stage_data['STAGE_VALUES'].RedThirst
  elseif char_id == character_data.CHARACTER_ID['Felicia']   then return stage_data['STAGE_VALUES'].TowerOfArrogance
  elseif char_id == character_data.CHARACTER_ID['Bishamon']  then return stage_data['STAGE_VALUES'].Abaraya
  elseif char_id == character_data.CHARACTER_ID['Aulbath']   then return stage_data['STAGE_VALUES'].GreenScream
  elseif char_id == character_data.CHARACTER_ID['Sasquatch'] then return stage_data['STAGE_VALUES'].ForeverTorment
  elseif char_id == character_data.CHARACTER_ID['QBee']      then return stage_data['STAGE_VALUES'].VanityParadise
  elseif char_id == character_data.CHARACTER_ID['LeiLei']    then return stage_data['STAGE_VALUES'].VanityParadise
  elseif char_id == character_data.CHARACTER_ID['Lilith']    then return stage_data['STAGE_VALUES'].DesertedChateau
  elseif char_id == character_data.CHARACTER_ID['Jedah']     then return stage_data['STAGE_VALUES'].FetusOfGod
  else                                                            return nil
  end
end

local function select_stage()
  local is_coin_pressed = manager.machine.ioport:type_pressed(manager.machine.ioport:token_to_input_type('COIN1'))

  -- TODO: map input tokens, etc. to game values
  -- TODO: consider API for ioport shit after above
  -- TODO: consider a breakpoint service that translates intuitive shit into debugger expressions
  -- TODO: debouncing lol, or figuring out a better way to read inputs
  if is_coin_pressed and not was_coin_pressed_last_frame then
    was_coin_pressed_last_frame = true
    selected_stage = resolve_char_id_to_stage_value(m.rbu(mem_map.player_data.p1_base_addr + mem_map.player_data.char_sel_cursor_pos.offset))
    if selected_stage ~= nil then
      if stage_bp > 0 then
        cpu.debug:bpclear(stage_bp)
        stage_bp = 0
      end
      stage_bp = cpu.debug:bpset(STAGE_WRITE_FUNC_MEMCPY_ADDR, '', 'D0 = #' .. tostring(selected_stage) .. '; g')
      manager.machine:popmessage('Selected ' .. stage_data.get_stage_name(selected_stage))
    end
  elseif not is_coin_pressed and was_coin_pressed_last_frame then
    was_coin_pressed_last_frame = false
  end
end

return {
  ['select_stage'] = select_stage,
}