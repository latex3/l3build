--[[

File l3build-aux.lua Copyright (C) 2018 The LaTeX3 Project

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

local match = string.match

local pairs = pairs
local print = print

local lookup = kpse.lookup

--
-- Auxiliary functions which are used by more than one main function
--

function normalise_epoch()
  -- If given as an ISO date, turn into an epoch number
  local y, m, d = match(epoch, "^(%d%d%d%d)-(%d%d)-(%d%d)$")
  if y then
    epoch =
      os_time({year = y, month = m, day = d, hour = 0, sec = 0, isdst = nil}) -
      os_time({year = 1970, month = 1, day = 1, hour = 0, sec = 0, isdst = nil})
  elseif match(epoch, "^%d+$") then
    epoch = tonumber(epoch)
  else
    epoch = 0
  end
end

function setepoch()
  return
    os_setenv .. " SOURCE_DATE_EPOCH=" .. epoch
      .. os_concat ..
    os_setenv .. " SOURCE_DATE_EPOCH_TEX_PRIMITIVES=1"
      .. os_concat ..
    os_setenv .. " FORCE_SOURCE_DATE=1"
      .. os_concat
end

local function getscriptname()
  if match(arg[0], "l3build$") or match(arg[0], "l3build%.lua$") then
    return lookup("l3build.lua")
  else
    return arg[0]
  end
end

-- Do some subtarget for all modules in a bundle
function call(dirs, target, opts)
  -- Turn the option table into a string
  local opts = opts or options
  local s = ""
  for k,v in pairs(opts) do
    if k ~= "names" and k ~= "target" then -- Special cases
      local t = option_list[k] or { }
      local arg = ""
      if t["type"] == "string" then
        arg = arg .. "=" .. v
      end
      if t["type"] == "table" then
        for _,a in pairs(v) do
          if arg == "" then
            arg = "=" .. a -- Add the initial "=" here
          else
            arg = arg .. "," .. a
          end
        end
      end
      s = s .. " --" .. k .. arg
    end
  end
  if opts["names"] then
    for _,v in pairs(opts["names"]) do
      s = s .. " " .. v
    end
  end
  local scriptname = getscriptname()
  for _,i in ipairs(dirs) do
    local text = " for module " .. i
    if i == "." then
      text = " with configuration " .. opts["config"][1]
    end
    print(
      "Running script " .. scriptname .. " with target \"" .. target
        .. "\"" .. text
    )
    local errorlevel = run(
      i,
      "texlua " .. scriptname .. " " .. target .. s
    )
    if errorlevel ~= 0 then
      return errorlevel
    end
  end
  return 0
end

-- Unpack files needed to support testing/typesetting/unpacking
function depinstall(deps)
  local errorlevel
  for _,i in ipairs(deps) do
    print("Installing dependency: " .. i)
    errorlevel = run(i, "texlua " .. getscriptname() .. " unpack -q")
    if errorlevel ~= 0 then
      return errorlevel
    end
  end
  return 0
end
