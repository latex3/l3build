--[[

File l3buildlib.lua Copyright (C) 2024 The LaTeX Project

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

--[[
  The very first call:
    require"l3buildlib"
  must occur before everything else.
  Then
    local l3b = require"l3buildlib"
  After that, we have access to `l3b.execute`.
]]

local M = { -- the return table
  _DESCRIPTION = "l3build core library"
}

local execute = os.execute -- Lua version 5.1 see https://tug.org/pipermail/luatex/2015-November/005535.html

---Execute a command sticking to version 5.1 output
---
---`texlua` 1.18 uses Lua 5.3 except for `os.execute` which is still 5.1.
---First print the argument when debugging.
---@param command string?
---@return integer
function M.execute(command)
  if options.debug then
    print('l3build execute: `'..tostring(command)..'`')
  end
  ---@diagnostic disable-next-line: return-type-mismatch
  return execute(command)
end

return M
