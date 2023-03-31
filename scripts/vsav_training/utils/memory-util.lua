require './scripts/vsav_training/constants/data-types'
local PROGRAM_MEMORY = manager.machine.devices[":maincpu"].spaces["program"]

local function read_u(addr, size)
  if size == BYTE then
    return PROGRAM_MEMORY:read_u8(addr)
  elseif size == WORD then
    return PROGRAM_MEMORY:read_u16(addr)
  elseif size == DWORD then
    return PROGRAM_MEMORY:read_u32(addr)
  elseif size == QWORD then
    return PROGRAM_MEMORY:read_u64(addr)
  end
end

local function read_i(addr, size)
  if size == BYTE then
    return PROGRAM_MEMORY:read_i8(addr)
  elseif size == WORD then
    return PROGRAM_MEMORY:read_i16(addr)
  elseif size == DWORD then
    return PROGRAM_MEMORY:read_i32(addr)
  elseif size == QWORD then
    return PROGRAM_MEMORY:read_i64(addr)
  end
end

local function write_u(addr, size, val)
  if size == BYTE then
    return PROGRAM_MEMORY:write_u8(addr, val)
  elseif size == WORD then
    return PROGRAM_MEMORY:write_u16(addr, val)
  elseif size == DWORD then
    return PROGRAM_MEMORY:write_u32(addr, val)
  elseif size == QWORD then
    return PROGRAM_MEMORY:write_u64(addr, val)
  end
end

local function write_i(addr, size, val)
  if size == BYTE then
    return PROGRAM_MEMORY:write_i8(addr, val)
  elseif size == WORD then
    return PROGRAM_MEMORY:write_i16(addr, val)
  elseif size == DWORD then
    return PROGRAM_MEMORY:write_i32(addr, val)
  elseif size == QWORD then
    return PROGRAM_MEMORY:write_i64(addr, val)
  end
end

local rbu = function(addr)
  return PROGRAM_MEMORY:read_u8(addr)
end

local rwu = function(addr)
  return PROGRAM_MEMORY:read_u16(addr)
end

local rdu = function(addr)
  return PROGRAM_MEMORY:read_u32(addr)
end

local rqu = function(addr)
  return PROGRAM_MEMORY:read_u64(addr)
end

local rbi = function(addr)
  return PROGRAM_MEMORY:read_i8(addr)
end

local rwi = function(addr)
  return PROGRAM_MEMORY:read_i16(addr)
end

local rdi = function(addr)
  return PROGRAM_MEMORY:read_i32(addr)
end

local rqi = function(addr)
  return PROGRAM_MEMORY:read_i64(addr)
end

local wbu = function(addr, val)
  PROGRAM_MEMORY:write_u8(addr, val)
end

local wwu = function(addr, val)
  PROGRAM_MEMORY:write_u16(addr, val)
end

local wdu = function(addr, val)
  PROGRAM_MEMORY:write_u32(addr, val)
end

local wqu = function(addr, val)
  PROGRAM_MEMORY:write_u64(addr, val)
end

local wbi = function(addr, val)
  PROGRAM_MEMORY:write_i8(addr, val)
end

local wwi = function(addr, val)
  PROGRAM_MEMORY:write_i16(addr, val)
end

local wdi = function(addr, val)
  PROGRAM_MEMORY:write_i32(addr, val)
end

local wqi = function(addr, val)
  PROGRAM_MEMORY:write_i64(addr, val)
end

return {
  ['ru'] = read_u,
  ['ri'] = read_i,
  ['wu'] = write_u,
  ['wi'] = write_i,
  ['rbu'] = rbu,
  ['rwu'] = rwu,
  ['rdu'] = rdu,
  ['rqu'] = rqu,
  ['rbi'] = rbi,
  ['rwi'] = rwi,
  ['rdi'] = rdi,
  ['rqi'] = rqi,
  ['wbu'] = wbu,
  ['wwu'] = wwu,
  ['wdu'] = wdu,
  ['wqu'] = wqu,
  ['wbi'] = wbi,
  ['wwi'] = wwi,
  ['wdi'] = wdi,
  ['wqi'] = wqi,
  ['mem'] = PROGRAM_MEMORY
}