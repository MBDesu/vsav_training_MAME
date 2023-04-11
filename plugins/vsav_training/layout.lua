local scripts = {}

local function prepare_layout(file, script)
  local env = {
    machine = manager.machine,
    emu = {
      attotime = emu.attotime,
      render_bounds = emu.render_bounds,
      render_color = emu.render_color,
      print_verbose = emu.print_verbose,
      print_error = emu.print_error,
      print_warning = emu.print_warning,
      print_info = emu.print_info,
      print_debug = emu.print_debug
    },
    file = file,
    print = print,
    pairs = pairs,
    ipairs = ipairs,
    string = string,
    tonumber = tonumber,
    tostring = tostring,
    table = table
  }

  print(script)
  local script, err = load(script, script, 't', env)
  if not script then
    print('error loading layout script ', err)
    return
  end
  local hooks = script()
  if hooks ~= nil then
    table.insert(scripts, hooks)
  end
end

emu.register_callback(prepare_layout, 'layout')
emu.register_frame(function()
  local input_viewer = require './vsav_training/input-viewer'
  if manager.machine.paused then
    return
  end
  for _, scr in pairs(scripts) do
    if scr.set_state then
      scr.set_state(input_viewer.p1_input_history[#input_viewer.p1_input_history])
    end
    if scr.frame then
      scr.frame()
    end
  end
end)
emu.register_start(function()
  for _, scr in pairs(scripts) do
    if scr.reset then
      scr.reset()
    end
  end
end)
emu.register_stop(function() scripts = {} end)