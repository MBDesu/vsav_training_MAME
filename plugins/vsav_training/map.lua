---Class representing a Map in Lua.
---@class Map
Map = {}

---Constructor. Returns a new empty map or a copy of the existing map.
---@param m? Map
---@return Map
function Map.new(m)
  local map = {}
  setmetatable(map, Map)
  if m then
    for k, v in pairs(m) do map[k] = v end
  end
  return map
end

---Get the size of the map.
---@param m Map
---@return integer
function Map.size(m)
  if m then return #m end
  return 0
end

---Empty the map.
---@param m Map
function Map.clear(m)
  if m then
    for k, _ in pairs(m) do
      m[k] = nil
      k = nil
    end
  end
end

---Check if a map contains a key.
---@param m Map
---@param key any
---@return boolean
function Map.contains_key(m, key)
  if m and key then
    return m[key] ~= nil
  end
  return false
end

---Check if a map contains a value.
---@param m Map
---@param value any
---@return boolean
function Map.contains_value(m, value)
  if m and value then
    for _, v in pairs(m) do
      if v == value then return true end
    end
  end
  return false
end

---Checks if map is identical by reference to another.
---@param m Map
---@param o any
---@return boolean
function Map.equals(m, o)
  if m and o then
    for k, v in pairs(m) do
      if not o[k] or v ~= o[k] then return false end
    end
  else
    return false
  end
  return true
end

---Gets a value by a key, if it exists.
---@param m self
---@param k any
---@return any|nil
function Map.get(m, k)
  if m and k then
    return m[k]
  end
  return nil
end

---Does what's on the tin.
---@param m Map
---@return boolean
function Map.is_empty(m)
  if m then return Map.size(m) < 1 else return true end
end

---Adds the specified value at the specified key.
---@param m Map
---@param k any
---@param v any
function Map.put(m, k, v)
  if m and k and v then
    m[k] = v
  end
end

---Adds all elements from another map.
---@param m Map
---@param o Map
function Map.put_all(m, o)
  if o then
    for k, v in pairs(o) do
      m[k] = v
    end
  end
end

---Removes a value from a map.
---@param m Map
---@param o any
function Map.remove(m, o)
  m[o] = nil
end

---Gets all keys of a map.
---@param m Map
---@return table
function Map.keys(m)
  local keys = {}
  for k, _ in pairs(m) do
    keys[#keys + 1] = k
  end
  return keys
end

---Gets all values of a map.
---@param m Map
---@return table
function Map.values(m)
  local values = {}
  if m then
    for _, v in pairs(m) do
      values[#values + 1] = v
    end
  end
  return values
end