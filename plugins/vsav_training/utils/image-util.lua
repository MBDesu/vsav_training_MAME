---@diagnostic disable: param-type-mismatch

local file = require './vsav_training/utils/file-util'

---Creates a bitmap object from raw bitmap image data. The bitmap must be
---square (that is, dimensionally) and in 32 bit RGBA format.
---@param filename string the filename of the raw 32 bit RGBA bitmap data
---@return bitmap
local function argb32_bitmap_from_square_rgba32_bitmap_data(filename)
  local bitmap_data_as_string = file.read_file_as_string(filename)
  local raw_bitmap_data_size = string.len(bitmap_data_as_string)
  local bitmap_square_size = math.floor(math.sqrt(raw_bitmap_data_size / DWORD))
  ---@type table<number>
  local argb_dword_table = {}
  for j = 1, raw_bitmap_data_size, DWORD do
    local rgba = table.pack(string.byte(bitmap_data_as_string, j, j + 3))
    local a = rgba[4] * 0x1000000
    local r = rgba[1] * 0x10000
    local g = rgba[2] * 0x100
    local b = rgba[3] * 0x1
    argb_dword_table[#argb_dword_table + 1] = a + r + g + b
  end
  argb_dword_table = CREATE_2D_ARRAY_FROM_1D_ARRAY(argb_dword_table, bitmap_square_size)
  local bitmap = emu.bitmap_argb32(bitmap_square_size, bitmap_square_size)
  for y, _ in ipairs(argb_dword_table) do
    for x, pixel in ipairs(argb_dword_table[y]) do
      bitmap:plot(x - 1, y - 1, pixel)
    end
  end
  return bitmap
end

---Scales a value relative to the UI's current xscale
---@param x number Desired y units, in `x_scale` scale
---@param x_scale number The scale to convert from
---@return number `x` scaled to the current UI `xscale`
local function scale_x(x, x_scale)
  return x * (manager.machine.render.ui_container.xscale / x_scale)
end

---Scales a value relative to the UI's current yscale
---@param y number Desired y units, in `y_scale` scale
---@param y_scale number The scale to convert from
---@return number `y` scaled to the current UI `yscale`
local function scale_y(y, y_scale)
  return y * (manager.machine.render.ui_container.yscale / y_scale)
end

---Scales a coordinate pair to the UI's current scaling. Useful for scaling
---elements to consistent sizes across UI.
---@param x number Desired x units, in `x_scale` scale
---@param y number Desired y units, in `y_scale` scale
---@param x_scale number Scale `x` is in
---@param y_scale number Scale `y` is in
---@return number x_units The number of `x` units in UI scale
---@return number y_units The number of `y` units in UI scale
local function scale_coordinate(x, y, x_scale, y_scale)
  return scale_x(x, x_scale), scale_y(y, y_scale)
end

return {
  ['argb32_bitmap_from_square_rgba32_bitmap_data'] = argb32_bitmap_from_square_rgba32_bitmap_data,
  ['scale_coordinate'] = scale_coordinate,
  ['scale_x'] = scale_x,
  ['scale_y'] = scale_y,
}