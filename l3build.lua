#!/usr/bin/env texlua

--[[

File l3build.lua Copyright (C) 2014-2020 The LaTeX Project

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

-- Version information
release_date = "2020-06-04"

local kpse = require("kpse")

local mode

if arg[1] and arg[1]:match("^%-%-") then
  mode = arg[1]:sub(3)
else
  mode = "normal"
end

--[==[
This script can be executed as

x1) `l3build blablabla`
x2) `texlua l3build.lua blablabla`
x3) `texlua path to l3build.lua blablabla`
x4) imported from some other script,
    typically in the main package dir or a subfolder

We would like to identify the subfolder case.
x1 is the normal way, x4 is used by latex2e for example
x2 and x3 can be used by l3build developers
who want a full control on the launched tool.

For average users: copy paste this one below
kpse.set_program_name("kpsewhich")
local kpse_dir = kpse.lookup("l3build.lua"):match(".*/")
local mode = arg[1]:sub(3) -- "advanced" or "unit"
local exe = "l3build-main-" .. mode .. ".lua"
local path = kpse_dir .. exe
os.exit(dofile(path):run(arg))

--]==]

kpse.set_program_name("kpsewhich")
local kpse_dir = kpse.lookup("l3build.lua"):match(".*/")
local launch_dir = arg[0]:match("^(.*/).*%.lua$") or "./"

local exe = "l3build-mode-" .. mode .. ".lua"
local path = package.searchpath(
  "?", launch_dir .. exe -- ';' not allowed in the launch dir
)  or package.searchpath(
  "?", kpse_dir .. exe
)

if not path then -- the mode is unknown
  exe = "l3build-mode-normal.lua"
  path = package.searchpath(
    "?", launch_dir .. exe
  )  or package.searchpath(
    "?", kpse_dir .. exe
  )
end

os.exit(dofile(path):run(arg, _ENV))
