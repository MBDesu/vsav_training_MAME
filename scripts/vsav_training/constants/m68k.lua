local reg = {
  A0 = 'A0', A1 = 'A1', A2 = 'A2', A3 = 'A3',
  A4 = 'A4', A5 = 'A5', A6 = 'A6', A7 = 'A7',
  D0 = 'D0', D1 = 'D1', D2 = 'D2', D3 = 'D3',
  D4 = 'D4', D5 = 'D5', D6 = 'D6', D7 = 'D7',
  IR = 'IR', PC = 'PC', SR = 'SR'
}

local ptr = {
  SP = 'SP', SSP = 'SSP', USP = 'USP'
}

local aux = {
  CURPC = 'CURPC',
  PREF_DATA = 'PREF_DATA',
  PREF_ADDR = 'PREF_ADDR',
  CURFLAGS = 'CURFLAGS'
}

local ccr_flag = { C = 'C', V = 'V', Z = 'Z', N = 'N', X = 'X' }
local ccr_mask = { C = 0x1, V = 0x2, Z = 0x4, N = 0x8, X = 0x20 }

return {
  ['reg'] = reg,
  ['ptr'] = ptr,
  ['aux'] = aux,
  ['ccr_flag'] = ccr_flag,
  ['ccr_mask'] = ccr_mask
}