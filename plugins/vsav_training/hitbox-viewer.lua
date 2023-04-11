-- Original code by dammit
-- Heavily modified by N-Bee and MBD
-- TODO: fix throw boxes
-- TODO: proxy block boxes
local mem_map = require './vsav_training/constants/memory-map'
local m68k = require './vsav_training/constants/m68k'
local m = require './vsav_training/utils/memory-util'
local cpu = require './vsav_training/utils/m68k-util'
local gui = manager.machine.screens[':screen']
local system = manager.machine.system

local any_true, get_thrower, insert_throw, define_box, get_x, get_y
local game, frame_buffer, throw_buffer
local config_globals

local box_types = {
  ['vulnerability']       = { color = 0x7777FF, fill = 0x40, init_fill = 0x40, outline = 0xFF },
  ['attack']              = { color = 0xFF0000, fill = 0x40, init_fill = 0x40, outline = 0xFF },
  ['proj. vulnerability'] = { color = 0x00FFFF, fill = 0x40, init_fill = 0x40, outline = 0xFF },
  ['proj. attack']        = { color = 0xFF66FF, fill = 0x40, init_fill = 0x40, outline = 0xFF },
  ['push']                = { color = 0x00FF00, fill = 0x20, init_fill = 0x20, outline = 0xFF },
  ['throw']               = { color = 0xFFFF00, fill = 0x40, init_fill = 0x40, outline = 0xFF },
  ['throwable']           = { color = 0xF0F0F0, fill = 0x20, init_fill = 0x20, outline = 0xFF },
}

local globals = {
	axis_color           = 0xFFFFFFFF,
	blank_color          = 0xFF000000,
	axis_size            = 12,
	mini_axis_size       = 2,
	blank_screen         = TRAINING_SETTINGS.TRAINING_OPTIONS.blank_screen,
	draw_axis            = true,
	draw_mini_axis       = false,
	draw_pushboxes       = true,
	draw_throwable_boxes = false,
	alpha                = TRAINING_SETTINGS.TRAINING_OPTIONS.fill_hitboxes,
	ground_throw_height  = 0x50,
}

local profile = {
 {
    games = { 'vsavj' },
    number = {
      players = 2,
      projectiles = 32
    },
    address = {
      player = mem_map.player_data.p1_base_addr,
      projectile = mem_map.projectile_data.projectiles_base_addr,
      screen_left = mem_map.global_settings.base_addr + mem_map.global_settings.screen_left.offset
    },
    offset = {
      object_space = 0x100,
      flip_x = 0x0B,
      hitbox_ptr = nil
    },
    box_list = {
      {
        anim_ptr = nil,
        addr_table_ptr = mem_map.player_data.push_box_ptr.offset,
        id_ptr = mem_map.player_data.push_box_id.offset,
        id_shift = 0x3,
        type = 'push'
      },
      {
        anim_ptr = nil,
        addr_table_ptr = mem_map.player_data.head_hurtbox_ptr.offset,
        id_ptr = mem_map.player_data.head_hurtbox_id.offset,
        id_shift = 0x3,
        type = 'vulnerability'
      },
      {
        anim_ptr = nil,
        addr_table_ptr = mem_map.player_data.body_hurtbox_ptr.offset,
        id_ptr = mem_map.player_data.body_hurtbox_id.offset,
        id_shift = 0x3,
        type = 'vulnerability'
      },
      {
        anim_ptr = nil,
        addr_table_ptr = mem_map.player_data.foot_hurtbox_ptr.offset,
        id_ptr = mem_map.player_data.foot_hurtbox_id.offset,
        id_shift = 0x3,
        type = 'vulnerability'
      },
      {
        anim_ptr = nil,
        addr_table_ptr = mem_map.player_data.push_box_ptr.offset,
        id_ptr = mem_map.player_data.push_box_id.offset,
        id_shift = 0x3,
        type = 'throwable'
      },
      {
        anim_ptr = mem_map.player_data.animation_ptr.offset,
        addr_table_ptr = mem_map.player_data.attack_box_ptr.offset,
        id_ptr = 0x0A, -- TODO: figure out what this is
        id_shift = 0x5,
        type = 'attack'
      }
    },
    breakpoints = {
      {
        ['vsavj'] = 0x029450, -- TODO: what's this?
        func = function()
          local stack = m.rdu(cpu.get_reg(m68k.reg.A7))
          local pc = cpu.get_reg(m68k.reg.A7)
          if stack ~= pc + 0x30 and stack ~= pc + 0xB2 and stack ~= pc + 0xBE then
            return
          end
          insert_throw({
            id = cpu.get_reg(m68k.reg.D0) & 0xFF,
            -- TODO: what's `0x98`?
            anim_ptr = nil, addr_table_ptr = mem_map.player_data.attack_box_ptr.offset, id_ptr = 0x98, id_shift = 0x5, type = 'throw'
          })
        end
      },
      {
        ['vsavj'] = 0x0191A2, -- TODO: what's this?
        func = function()
          local stack = { cpu.get_reg(m68k.reg.A7), cpu.get_reg(m68k.reg.A7) + 4 }
          local target = 0x029472 -- TODO: what's this?
          if any_true({
            stack[1] ~= target,
            stack[2] == target + 0x0E, -- TODO: what's this?
            stack[2] == target + 0x90, -- TODO: what's this?
            stack[2] == target + 0x9C
          }) then
            return
          end
          cpu.set_reg(m68k.reg.D1, 0)
        end
      },
      {
        ['vsavj'] = 0x029638,
        func = function()
          local base = cpu.get_reg(m68k.reg.A4)
          insert_throw({
            id = m68k.reg.D0 & 0xFF,
            pos_x = get_x(m.rwi(base + game.offset.pos_x)),
            pos_y = get_y(m.rwi(base + game.offset.pos_y)),
            anim_ptr = nil, addr_table_ptr = mem_map.player_data.attack_box_ptr.offset, id_ptr = 0x98, id_shift = 0x5, type = 'throw'
          })
        end
      },
    },
    process_throw = function(obj, box)
      return define_box[game.box_type](obj,box)
    end,
    friends = { 0x08, 0x10, 0x11, 0x37 },
    active = function() return any_true({
      (m.rdu(0xFF8004) == 0x40000 and m.rdu(0xFF8008) == 0x40000),
      (m.rwu(0xFF8008) == 0x2 and m.rwu(0xFF800A) > 0)
    }) end,
    invulnerable = function(obj, box)
      return any_true({
        m.rbu(obj.base + 0x134) > 0,
        m.rbu(obj.base + 0x147) > 0,
        m.rbu(obj.base + 0x11E) > 0,
        m.rbu(obj.base + 0x145) > 0 and m.rbu(obj.base + 0x1A4) == 0
      }) end,
    unpushable = function(obj, box) return any_true({
      m.rbu(obj.base + 0x134) > 0
    }) end,
    unthrowable = function(obj, box) return any_true({
      not (m.rwu(obj.base + 0x004) == 0x0200 or m.rwu(obj.base + 0x004) == 0x0204),
      m.rbu(obj.base + 0x143) > 0,
      m.rbu(obj.base + 0x147) > 0,
      m.rbu(obj.base + 0x11E) > 0,
      m.rdu(obj.base + 0x094) & 0xFFFFFF00 == 0
    }) end
  }
}

for game in ipairs(profile) do
  local g = profile[game]
  g.box_type = g.offset.id_ptr and 'id ptr' or 'hitbox ptr'
  g.ground_level = g.ground_level or -0x0F
  g.offset.player_space = g.offset.player_space or 0x400
  g.offset.pos_x = g.offset.pos_x or 0x10
  g.offset.pos_y = g.offset.pos_y or g.offset.pos_x + 0x4
  g.offset.hitbox_ptr = g.offset.hitbox_ptr or {}
  g.box = g.box or {}
  g.box.radius_read = g.box.radius_read or m.rwu
  g.box.offset_read = g.box.radius_read == m.rwu and m.rwi or m.rbi
  g.box.val_x    = g.box.val_x or 0x0
  g.box.val_y    = g.box.val_y or 0x2
  g.box.rad_x    = g.box.rad_x or 0x4
  g.box.rad_y    = g.box.rad_y or 0x6
  g.box.radscale = g.box.radscale or 1
  g.no_hit       = g.no_hit       or function() end
  g.invulnerable = g.invulnerable or function() end
  g.unpushable   = g.unpushable   or function() end
  g.unthrowable  = g.unthrowable  or function() end
  g.projectile_active = g.projectile_active or function(obj)
    if m.rwu(obj.base) > 0x0100 and m.rbu(obj.base + 0x04) == 0x02 then
      return true
    end
  end
  g.special_projectiles = g.special_projectiles or { number = 0 }
  g.breakables = g.breakables or { number = 0 }
end

local function config_hitbox_fill()
  for _, box in pairs(box_types) do
    if globals.alpha then
      box.fill = (box.init_fill * 0x1000000) + box.color
    else
      box.fill = 0x00000000 + box.color
    end
    box.outline = 0xFF000000 + box.color
  end
end
config_hitbox_fill()

local projectile_type = {
  ['attack'] = 'proj. attack',
  ['vulnerability'] = 'proj. vulnerability'
}

local DRAW_DELAY = 1

any_true = function(condition)
  for i = 1, #condition do
    if condition[i] == true then return true end
  end
end

get_thrower = function(frame)
  local base = 0xFFFFFF & cpu.get_reg(m68k.reg.A6)
  for _, obj in ipairs(frame) do
    if base == obj.base then
      return obj
    end
  end
end

insert_throw = function(box)
  local f = frame_buffer[DRAW_DELAY]
  local obj = get_thrower(f)
  if not f.match_active or not obj then
    return
  end
  table.insert(throw_buffer[obj.base], game.process_throw(obj, box))
end

get_x = function(x)
  return x - frame_buffer[DRAW_DELAY + 1].screen_left
end

get_y = function(y)
  return gui.height - (y + game.ground_level) + frame_buffer[DRAW_DELAY + 1].screen_top
end

local process_box_type = {
  ['vulnerability'] = function(obj, box)
    if game.invulnerable(obj, box) or obj.friends then
      return false
    end
  end,
  ['attack'] = function(obj, box)
    if game.no_hit(obj, box) then
      return false
    end
  end,
  ['push'] = function(obj, box)
    if game.unpushable(obj, box) or obj.friends then
      return false
    end
  end,
  ['throw'] = function(obj, box)
    if box.clear then
      m.wbu(obj.base + box.id_ptr, 0)
    end
  end,
  ['throwable'] = function(obj, box)
    if game.unthrowable(obj, box) or obj.projectile then
      return false
    end
  end
}

define_box = {
  ['hitbox ptr'] = function(obj, box_entry)
    local box = DEEP_COPY(box_entry)
    if obj.projectile and box.no_projectile then
      return nil
    end
    if not box.id then
      box.id_base = (box.anim_ptr and m.rdu(obj.base + box.anim_ptr)) or obj.base
      box.id = m.rbu(box.id_base + box.id_ptr)
    end
    if process_box_type[box.type](obj, box) == false or box.id == 0 then
      return nil
    end
    local addr_table
    if not obj.hitbox_ptr then
      addr_table = m.rdu(obj.base + box.addr_table_ptr)
    else
      local table_offset = obj.projectile and box.p_addr_table_ptr or box.addr_table_ptr
      addr_table = obj.hitbox_ptr + m.rwi(obj.hitbox_ptr + table_offset)
    end
    box.address = addr_table + (box.id << box.id_shift)
    box.rad_x = game.box.radius_read(box.address + game.box.rad_x) / game.box.radscale
    box.rad_y = game.box.radius_read(box.address + game.box.rad_y) / game.box.radscale
    box.val_x = game.box.offset_read(box.address + game.box.val_x)
    box.val_y = game.box.offset_read(box.address + game.box.val_y)
    if box.type == 'push' then
      obj.val_y, obj.rad_y = box.val_y, box.rad_y
    end
    box.val_x  = (box.pos_x or obj.pos_x) + box.val_x * obj.flip_x
    box.val_y  = (box.pos_y or obj.pos_y) - box.val_y
    box.left   = box.val_x - box.rad_x
    box.right  = box.val_x + box.rad_x
    box.top    = box.val_y - box.rad_y
    box.bottom = box.val_y + box.rad_y
    box.type   = obj.projectile and not obj.friends and projectile_type[box.type] or box.type
    return box
  end
}

local get_ptr = {
  ['hitbox ptr'] = function(obj)
    obj.hitbox_ptr = obj.projectile and game.offset.hitbox_ptr.projectile or game.offset.hitbox_ptr.player
    obj.hitbox_ptr = obj.hitbox_ptr and m.rdu(obj.base + obj.hitbox_ptr) or nil
  end
}

local update_object = function(obj)
  obj.flip_x = m.rbu(obj.base + game.offset.flip_x) > 0 and -1 or 1
  obj.pos_x  = get_x(m.rwi(obj.base + game.offset.pos_x))
  obj.pos_y  = get_y(m.rwi(obj.base + game.offset.pos_y))
  get_ptr[game.box_type](obj)
  for _, box_entry in ipairs(game.box_list) do
    table.insert(obj, define_box[box_entry.method or game.box_type](obj, box_entry))
  end
  return obj
end

local friends_status = function(id)
  for _, friend in ipairs(game.friends or {}) do
    if id == friend then
      return true
    end
  end
end

local read_projectiles = function(f)
  for i = 1, game.number.projectiles do
    local obj = { base = game.address.projectile + (i - 1) * game.offset.object_space }
    if game.projectile_active(obj) then
      obj.projectile = true
      obj.friends = friends_status(m.rbu(obj.base + 0x02))
      table.insert(f, update_object(obj))
    end
  end
end

local update_hitboxes = function()
  if not game or not TRAINING_SETTINGS.TRAINING_OPTIONS.show_hitboxes then
    return
  end
  local screen_left_ptr = game.address.screen_left or game.get_cam_ptr()
  local screen_top_ptr  = game.address.screen_top or screen_left_ptr + 0x4
  for f = 1, DRAW_DELAY do
    frame_buffer[f] = DEEP_COPY(frame_buffer[f + 1])
  end

  frame_buffer[DRAW_DELAY + 1] = {
    match_active = game.active(),
    screen_left  = m.rwi(screen_left_ptr),
    screen_top   = m.rwi(screen_top_ptr),
  }
  local f = frame_buffer[DRAW_DELAY + 1]
  if not f.match_active then
    return
  end

  for p = 1, game.number.players do
    local player = { base = game.address.player + (p - 1) * game.offset.player_space }
    if m.rbu(player.base) > 0 then
      table.insert(f, update_object(player))
      local tb = throw_buffer[player.base]
      table.insert(player, tb[1])
      for frame = 1, #tb - 1 do
        tb[frame] = tb[frame + 1]
      end
      table.remove(tb)
    end
  end
  read_projectiles(f)

  f = frame_buffer[DRAW_DELAY]
  for _, obj in ipairs(f or {}) do
    if obj.projectile then
      break
    end
    for _, box_entry in ipairs(game.throw_box_list or {}) do
      if not (emu.registerfuncs and box_entry.clear) then
        table.insert(obj, define_box[box_entry.method or game.box_type](obj, box_entry))
      end
    end
  end

  f.max_boxes = 0
  for _, obj in ipairs(f or {}) do
    f.max_boxes = math.max(f.max_boxes, #obj)
  end
  f.max_boxes = f.max_boxes + 1
end

local draw_hitbox = function(hb)
  if not hb or any_true({
        not globals.draw_pushboxes and hb.type == 'push',
        not globals.draw_throwable_boxes and hb.type == 'throwable'
      }) then
    return
  end

  if globals.draw_mini_axis then
    gui:draw_line(hb.val_x, hb.val_y - globals.mini_axis_size, hb.val_x, hb.val_y + globals.mini_axis_size, box_types[hb.type].outline)
    gui:draw_line(hb.val_x - globals.mini_axis_size, hb.val_y, hb.val_x + globals.mini_axis_size, hb.val_y, box_types[hb.type].outline)
  end

  gui:draw_box(hb.left, hb.top, hb.right, hb.bottom, box_types[hb.type].outline, box_types[hb.type].fill)
end


local draw_axis = function(obj)
  gui:draw_line(obj.pos_x, obj.pos_y - globals.axis_size, obj.pos_x, obj.pos_y + globals.axis_size, globals.axis_color)
  gui:draw_line(obj.pos_x - globals.axis_size, obj.pos_y, obj.pos_x + globals.axis_size, obj.pos_y, globals.axis_color)
end

local render_hitboxes = function()
  local pushes = {}
  local hitboxes = {}
  local hurtboxes = {}

  local f = frame_buffer[1]
  if not f.match_active or not TRAINING_SETTINGS.TRAINING_OPTIONS.show_hitboxes then
    return
  end
  if TRAINING_SETTINGS.TRAINING_OPTIONS.fill_hitboxes ~= globals.alpha then
    globals.alpha = TRAINING_SETTINGS.TRAINING_OPTIONS.fill_hitboxes
    config_hitbox_fill()
  end
  if TRAINING_SETTINGS.TRAINING_OPTIONS.blank_screen then
    gui:draw_box(0, 0, gui.width, gui.height, globals.blank_color, globals.blank_color)
  end
  for entry = 1, f.max_boxes or 0 do
    for _, obj in ipairs(f) do
      if obj[entry] then
        if obj[entry]['type'] == 'push' then
          local cur_pushes = obj[entry]
          if not pushes.p1 then
            pushes.p1 = cur_pushes
          end
          if pushes.p1 then
            if cur_pushes.right ~= pushes.p1.right then
              pushes.p2 = cur_pushes
            end
          end
        end
        if obj[entry]['type'] == 'vulnerability' then
          local cur_hurtbox = obj[entry]
          table.insert(hurtboxes, cur_hurtbox)
        end
        if obj[entry]['type'] == 'attack' then
          local cur_hitbox = obj[entry]
          table.insert(hitboxes, cur_hitbox)
        end
      end
      -- if config_globals.options.display_hitbox_default == true then
        draw_hitbox(obj[entry])
      -- end
    end
  end
  globals.pushboxes = pushes
  -- if config_globals.options.display_hitbox_default == true then
    if globals.draw_axis then
      for _, obj in ipairs(f) do
        draw_axis(obj)
      end
    end
  -- end
end

local initialize_bps = function()
  -- for _, pc in ipairs(globals.breakpoints or {}) do
  --   memory.registerexec(pc, nil)
  -- end
  -- for _, addr in ipairs(globals.watchpoints or {}) do
  --   memory.registerwrite(addr, nil)
  -- end
  globals.breakpoints, globals.watchpoints = {}, {}
end


local initialize_fb = function()
  frame_buffer = {}
  for f = 1, DRAW_DELAY + 1 do
    frame_buffer[f] = {}
  end
end


local initialize_throw_buffer = function()
  throw_buffer = {}
  for p = 1, game.number.players do
    throw_buffer[game.address.player + (p - 1) * game.offset.player_space] = {}
  end
end


local whatgame = function()
  game = nil
  initialize_fb()
  initialize_bps()
  for _, module in ipairs(profile) do
    for _, shortname in ipairs(module.games) do
      if system.name == shortname or system.parent == shortname then
        game = module
        initialize_throw_buffer()
        if not emu.registerfuncs then
          return
        end
        for _, bp in ipairs(game.breakpoints or {}) do
          local pc = bp[system.name] or bp[system.parent] + game.clones[system.name]
          -- memory.registerexec(pc, bp.func)
          table.insert(globals.breakpoints, pc)
        end
        for _, wp in ipairs(game.watchpoints or {}) do
          for p = 1, game.number.players do
            local addr = game.address.player + (p - 1) * game.offset.player_space + wp.offset
            -- memory.registerwrite(addr, wp.size, wp.func)
            table.insert(globals.watchpoints, addr)
          end
        end
        return
      end
    end
  end
end

return {
  ['start'] = function()
    whatgame()
    initialize_fb()
  end,
  ['register_frame'] = update_hitboxes,
  ['register_frame_done'] = render_hitboxes
}