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

local function print_n_spaces(n)
  local spaces = ''
  if n > 0 then
    for i = 0, n do
      spaces = spaces .. ' '
    end
  end
  io.write(spaces)
end

-- this thing sucks, but it does what I need it to
function PRINT_TABLE(table, depth)
  depth = depth or 0
  print()
  print_n_spaces(2 * depth)
  print('{')
  for k, v in pairs(table) do
    print_n_spaces(2 * (depth + 1))
    io.write(tostring(k) .. ': ')
    if type(v) == 'table' then
      PRINT_TABLE(v, depth + 1)
    else
      print(tostring(v))
    end
  end
  print_n_spaces(2 * depth)
  print('}')
end

function ASCII_KEYCODE_TO_INT(ascii_value)
  if ascii_value > 0x39 and ascii_value < 0x30 then return nil end
  return ascii_value & 0x0F;
end