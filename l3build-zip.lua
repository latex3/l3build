--[[

File l3build-zip.lua Copyright (C) 2021-2024 The LaTeX Project

It may be distributed and/or modified under the conditions of the
LaTeX Project Public License (LPPL), either version 1.3c of this
license or (at your option) any later version.  The latest version
of this license is in the file

   https://www.latex-project.org/lppl.txt

This file is part of the "l3build bundle" (The Work in LPPL)
and all files in that bundle must be distributed together.

-----------------------------------------------------------------------

The development version of the bundle can be found at

   https://github.com/latex3/l3build

for those people who are interested.

--]]

local concat = table.concat
local open = io.open
local osdate = os.date
local pack = string.pack
local setmetatable = setmetatable
local iotype = io.type

local compress = zlib.compress
local crc32 = zlib.crc32

local function encode_time(unix)
  local t = osdate('*t', unix)
  local date = t.day | (t.month << 5) | ((t.year-1980) << 9)
  local time = (t.sec//2) | (t.min << 5) | (t.hour << 11)
  return date, time
end

local function extra_timestamp(mod, access, creation)
  local flags = 0
  local local_extra, central_extra = '', ''
  if mod then
    flags = flags | 0x1
    local_extra = pack('<I4', mod)
    central_extra = local_extra
  end
  if access then
    flags = flags | 0x2
    local_extra = local_extra .. pack('<I4', access)
  end
  if creation then
    flags = flags | 0x4
    local_extra = local_extra .. pack('<I4', creation)
  end
  if flags == 0 then return '', '' end
  return pack('<c2I2B', 'UT', #central_extra + 1, flags) .. central_extra, pack('<c2I2B', 'UT', #local_extra + 1, flags) .. local_extra
end

local meta = {__index = {
  add = function(z, filename, innername, binary, executable)
    innername = innername or filename

    local offset = z.f:seek'cur'

    local content do
      local f = iotype(filename) and filename or assert(open(filename, binary and 'rb' or 'r'))
      content = f:read'*a'
      f:close()
    end
    local crc32 = crc32(crc32(), content)
    local compressed = compress(content, nil, nil, -15)
    if #compressed >= #content then
      compressed = nil
    end
    local timestamp = os.time()
    local date, time = encode_time(timestamp)
    local central_extra, local_extra = extra_timestamp(timestamp, nil, nil)
    z.f:write(pack("<c4I2I2I2I2I2I4I4I4I2I2",
        'PK\3\4',
        compressed and 20 or 10, -- ZIP 2.0 to allow deflate
        0, -- We never set flags
        compressed and 8 or 0, -- Always use deflate
        time,
        date,
        crc32,
        compressed and #compressed or #content,
        #content,
        #innername,
        #local_extra),
      innername,
      local_extra,
      compressed or content)
    local central = pack("<c4I2I2I2I2I2I2I4I4I4I2I2I2I2I2I4I4",
        'PK\1\2',
        (3 << 8) | 63, -- Use UNIX attributes, written against ZIP 6.3
        compressed and 20 or 10, -- ZIP 2.0 to allow deflate
        0, -- We never set flags
        compressed and 8 or 0, -- Always use deflate
        time,
        date,
        crc32,
        compressed and #compressed or #content,
        #content,
        #innername,
        #central_extra,
        0, -- no comment
        0, -- Disc 0
        binary and 0 or 1,
        (executable and 0x81ED--[[0100755]] or 0x81A4--[[0100644]]) << 16,
        offset)
    z.central[#z.central+1] = central .. innername .. central_extra
  end,
  close = function(z, comment)
    comment = comment or ''

    local offset = z.f:seek'cur'
    local central = concat(z.central)
    z.f:write(central, pack("<c4I2I2I2I2I4I4I2",
        'PK\5\6',
        0, -- This is disc 0
        0, -- central dictionary started on disc 0
        #z.central, -- Central disctionary entries on this disc
        #z.central, -- Central disctionary entries on all discs
        #central,
        offset,
        #comment), comment)
    return z.f:close()
  end,
}}

return function(filename)
  local f, msg = open(filename, 'wb') -- closed just above
  if not f then return f, msg end
  return setmetatable({
    f = f,
    offset = 1,
    central = {},
  }, meta)
end
