---Workspace to do debugging stuff in

-- local c = require './vsav_training/utils/m68k-util'

-- local function generic_read_callback(offset, data)
--   print(string.format('Data at %06x read: %08x', offset, data))
--   print('stack trace')
--   c.print_stack_trace()
--   print()
--   c.print_state()
--   print('\n==========================================\n')
-- end

-- local function generic_write_callback(offset, data)
--   print(string.format('Data at %06x written: %08x', offset, data))
--   print('stack trace')
--   c.print_stack_trace()
--   print()
--   c.print_state()
--   print('\n==========================================\n')
-- end

-- local read_watches = {
--   {
--     name = '5LP',
--     start_addr = 0x93f34,
--     size = 0x20,
--     callback = generic_read_callback
--   },
--   {
--     name = 'Box ptr read',
--     start_addr = 0xff848c,
--     size = WORD,
--     callback = generic_read_callback
--   }
-- }

-- local write_watches = {
--   {
--     name = 'Box ptr write',
--     start_addr = 0xff848c,
--     size = WORD,
--     callback = generic_write_callback
--   },
-- }

-- for _, data in pairs(read_watches) do
--   MEM_WATCH_SERVICE.watch_reads(data.name, data.start_addr, data.size, data.callback);
-- end

-- for _, data in pairs(write_watches) do
--   MEM_WATCH_SERVICE.watch_writes(data.name, data.start_addr, data.size, data.callback);
-- end