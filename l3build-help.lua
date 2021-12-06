--[[

File l3build-help.lua Copyright (C) 2018,2020,2021 The LaTeX Project

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

local insert = table.insert
local match  = string.match
local rep    = string.rep
local sort   = table.sort

local copyright = "Copyright (C) 2014-2021 The LaTeX Project\n"

function version()
  print(
    "\n" ..
    "l3build: A testing and building system for LaTeX\n\n" ..
    "Release " .. release_date .. "\n" ..
    copyright
  )
end

function help()
  local function setup_list(list)
    local longest = 0
    for k,_ in pairs(list) do
      if k:len() > longest then
        longest = k:len()
      end
    end
    -- Sort the options
    local t = { }
    for k,_ in pairs(list) do
      insert(t, k)
    end
    sort(t)
    return longest,t
  end

  local scriptname = "l3build"
  if not (match(arg[0], "l3build%.lua$") or match(arg[0],"l3build$")) then
    scriptname = arg[0]
  end
  print("usage: " .. scriptname .. " <target> [<options>] [<names>]")
  print("")
  print("Valid targets are:")
  local longest,t = setup_list(target_list)
  for _,k in ipairs(t) do
    local target = target_list[k]
    local filler = rep(" ", longest - k:len() + 1)
    if target["desc"] then
      print("   " .. k .. filler .. target["desc"])
    end
  end
  print("")
  print("Valid options are:")
  longest,t = setup_list(option_list)
  for _,k in ipairs(t) do
    local opt = option_list[k]
    local filler = rep(" ", longest - k:len() + 1)
    if opt["desc"] then
      if opt["short"] then
        print("   --" .. k .. "|-" .. opt["short"] .. filler .. opt["desc"])
      else
        print("   --" .. k .. "   " .. filler .. opt["desc"])
      end
    end
  end
  print("")
  print("Full manual available via 'texdoc l3build'.")
  print("")
  print("Repository  : https://github.com/latex3/l3build")
  print("Bug tracker : https://github.com/latex3/l3build/issues")
  print(copyright)
end
