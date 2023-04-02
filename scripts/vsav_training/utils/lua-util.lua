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

function ASCII_KEYCODE_TO_INT(ascii_value)
  if ascii_value > 0x39 and ascii_value < 0x30 then return nil end
  return ascii_value & 0x0F;
end