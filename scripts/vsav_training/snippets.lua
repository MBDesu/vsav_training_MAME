function some_other_function(offset, data, mask)
  print(manager.machine.screens[':screen']:frame_number(),
    manager.machine.devices[':maincpu'].spaces['program']:read_u8(0xFF8081),
    manager.machine.devices[':maincpu'].spaces['program']:read_u8(0xFF80B4),
    string.format('%x', offset),
    string.format('%x', data),
    string.format('%x', mask))
end
passthrough = manager.machine.devices[':maincpu'].spaces['program']:install_write_tap(0xFF8118, 0xFF8119, 'frameskip_flag', function(offset, data, mask)
  some_other_function(offset, data, mask)
  return
end)

  -- for k, v in pairs(manager.machine.ioport.types) do
  --   print(k, v.name)
  --   print(k, v.type)
  --   print(k, v.group)
  --   print(k, v.player)
  --   print(k, v.token)
  --   print(k, v.name)
  --   print('===================')
  -- end
-- symbols = emu.symbol_table(manager.machine.devices[':maincpu'])
-- fskip_symbol = symbols:add('fskip')
-- expr = emu.parsed_expression(symbols)
-- expr:parse('fskip = D0')
-- manager.machine.devices[':maincpu'].debug:bpset(0x8E5A, '', expr:execute())