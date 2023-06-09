local json = require './vsav_training/dependencies/dkjson'

---@param file_path string
---@return string|nil
local function read_file_as_string(file_path)
  local file, err = io.open(file_path, 'r')
  if not file then
    print('couldn\'t open' .. file_path, err)
    return nil
  end
  return file:read('a')
end

local function parse_json_file_to_object(file_path)
  local file, err = io.open(file_path, 'r')
  if not file then
    print('couldn\'t open ' .. file_path, err)
    return nil
  end
  local obj = json.decode(file:read('a'))
  file:close()
  return obj
end

local function parse_object_to_json_file(object, file_path)
  local file, err = io.open(file_path, 'w+')
  if not file then
    print('couldn\'t open ' .. file_path, err)
    return nil
  end
  local json_string = json.encode(object, { indent = true })
  if type(json_string) == 'string' then
    file:write(json_string)
  else
    file:close()
    return json_string
  end
  file:close()
  return true
end

local function parse_training_settings()
  -- TODO: error handling to default to settings.lua values if fails
  TRAINING_SETTINGS = parse_json_file_to_object(SCRIPT_SETTINGS.training_settings_file)
end

local function save_training_settings()
  -- TODO: error handling
  parse_object_to_json_file(TRAINING_SETTINGS, SCRIPT_SETTINGS.training_settings_file)
end

return {
  ['parse_training_settings'] = parse_training_settings,
  ['save_training_settings'] = save_training_settings,
  ['parse_object_to_json_file'] = parse_object_to_json_file,
  ['parse_json_file_to_object'] = parse_json_file_to_object,
  ['read_file_as_string'] = read_file_as_string,
}