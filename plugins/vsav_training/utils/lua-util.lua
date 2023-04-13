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
end

local function octal2Bin(octal_num)
  local oct2bin = {
    ['0'] = '000',
    ['1'] = '001',
    ['2'] = '010',
    ['3'] = '011',
    ['4'] = '100',
    ['5'] = '101',
    ['6'] = '110',
    ['7'] = '111'
  }
  return oct2bin[octal_num]
end

function NUM_TO_BIN_STR(num)
  local s = string.format('%o', num)
  s = s:gsub('.', octal2Bin)
  return s
end

---Filters a table by values based on a predicate function and returns the remaining elements
---@generic T
---@param table table<T>
---@param condition fun(item: T): boolean
---@return table
---@nodiscard
function FILTER_TABLE_BY_VALUE(table, condition)
  local result = {}
  for k, v in pairs(table) do
    if condition(v) then
      result[k] = v
    end
  end
  return result
end

---Filters a table by keys based on a predicate function and returns the remaining elements
---@generic T
---@param table table<T>
---@param condition fun(item: T): boolean
---@return table
---@nodiscard
function FILTER_TABLE_BY_KEY(table, condition)
  local result = {}
  for k, v in pairs(table) do
    if condition(k) then
      result[k] = v
    end
  end
  return result
end

---Creates a 2D array from a 1D array, returning the 2D array
---@generic T
---@param tbl table<T>
---@param row_length number
---@return table<table<T>>
---@nodiscard
function CREATE_2D_ARRAY_FROM_1D_ARRAY(tbl, row_length)
  local result = { {} }
  for i, v in ipairs(tbl) do
    result[#result][#result[#result] + 1] = v
    if i % row_length == 0 and i < #tbl then
      result[#result + 1] = {}
    end
  end
  return result
end