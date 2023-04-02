function DEEP_COPY(original)
  local type = type(original)
  local copy
  if type == 'table' then
    copy = {}
    for k, v in next, original, nil do
      copy[DEEP_COPY(k)] = DEEP_COPY(v)
    end
    setmetatable(copy, DEEP_COPY(getmetatable(original)))
  else
    copy = original
  end
  return copy
end

local function write_n_spaces_m_times(n, m)
  for i = 0, m do
    for j = 0, n do
      io.write(' ')
    end
  end
end

-- this thing sucks, but it does what I need it to
function PRINT_TABLE(table, depth)
  depth = depth or 0
  if depth > 0 then
    write_n_spaces_m_times(2, depth)
  end
  print('{')
  for k, v in pairs(table) do
    if depth > 0 then
      write_n_spaces_m_times(2, depth)
    end
    io.write(tostring(k) .. ': ')
    if type(v) == 'table' then
      PRINT_TABLE(v, depth + 1)
    else
      print(tostring(v))
    end
  end
  if depth > 0 then
    write_n_spaces_m_times(2, depth)
  end
  print('}')
end

function ASCII_KEYCODE_TO_INT(ascii_value)
  if ascii_value > 0x39 and ascii_value < 0x30 then return nil end
  return ascii_value & 0x0F;
end