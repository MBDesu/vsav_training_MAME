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