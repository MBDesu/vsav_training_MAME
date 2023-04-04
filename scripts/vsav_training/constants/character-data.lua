local character_id = {
  Bulleta    = 0x0,
  Demitri    = 0x1,
  Gallon     = 0x2,
  Victor     = 0x3,
  Zabel      = 0x4,
  Morrigan   = 0x5,
  Anakaris   = 0x6,
  Felicia    = 0x7,
  Bishamon   = 0x8,
  Aulbath    = 0x9,
  Sasquatch  = 0xA,
  Random     = 0xB,
  QBee       = 0xC,
  LeiLei     = 0xD,
  Lilith     = 0xE,
  Jedah      = 0xF,
  DarkGallon = 0x2,
  Oboro      = 0x8
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