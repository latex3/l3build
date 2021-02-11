#!/usr/bin/env texlua

--[[

File l3build-main-advanced.lua Copyright (C) 2014-2020 The LaTeX Project

It may be distributed and/or modified under the conditions of the
LaTeX Project Public License (LPPL), either version 1.3c of this
license or (at your option) any later version.  The latest version
of this license is in the file

   http://www.latex-project.org/lppl.txt

This file is part of the "l3build bundle" (The Work in LPPL)
and all files in that bundle must be distributed together.

-----------------------------------------------------------------------

The development version of the bundle can be found at

   https://github.com/latex3/l3build

for those people who are interested.

--]]

release_date = "2020-06-04"

local _NAME = "main-advanced"

local M = {
  _TYPE = "module",
  _NAME = _NAME,
  _VERSION = "dev",
}

function M:run(arg)
  print("Welcome to " .. _NAME)
  return 0
end

return M
