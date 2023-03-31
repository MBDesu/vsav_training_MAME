local character_id = {
  Bulleta    = 0x00,
  Demitri    = 0x01,
  Gallon     = 0x02,
  Victor     = 0x03,
  Zabel      = 0x04,
  Morrigan   = 0x05,
  Anakaris   = 0x06,
  Felicia    = 0x07,
  Bishamon   = 0x08,
  Aulbath    = 0x09,
  Sasquatch  = 0x0A,
  Random     = 0x0B,
  QBee       = 0x0C,
  LeiLei     = 0x0D,
  Lilith     = 0x0E,
  Jedah      = 0x0F,
  DarkGallon = 0x12,
  Oboro      = 0x18
}

local id_character_map = {}
do
  for k, v in pairs(character_id) do
    id_character_map[v] = k
  end
end

return {
  ['CHARACTER_ID'] = character_id,
  ['ID_CHARACTER_MAP'] = id_character_map
}