--[[

File l3build-help.lua Copyright (C) 2018-2026 The LaTeX Project

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

local insert = table.insert
local match  = string.match
local rep    = string.rep
local sort   = table.sort

local copyright = "Copyright (C) 2014-2026 The LaTeX Project\n"

function version()
  print(
    "\n" ..
    "l3build: A testing and building system for LaTeX\n\n" ..
    "Release " .. release_date .. "\n" ..
    copyright
  )
end

local function scriptname()
  local scriptname = "l3build"
  if not (match(arg[0], "l3build%.lua$") or match(arg[0],"l3build$")) then
    scriptname = arg[0]
  end
  return scriptname
end

local function help_overview()
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

  print("\nUsage: " .. scriptname() .. " <target> [<options>] [<names>]")
  print("")
  print("Valid targets are:")
  local longest,t = setup_list(target_list)
  local extra_help = false
  for _,k in ipairs(t) do
    local target = target_list[k]
    local filler = rep(" ", longest - k:len() + 1)
    if target["desc"] then
      print("   " .. k .. filler .. target["desc"] .. (target["help"] and "*" or ""))
    end
    if target["help"] then
        extra_help = true
    end
  end
  print("")
  if extra_help then
    print('* Extra help available via "' .. scriptname() .. ' <target> --help"' )
    print("")
  end
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

local function help_target(target)
  if target_list[target] then
    print("\nUsage: " .. scriptname() .. " " .. target .. " [<options>] [<names>]")
    print("")
    if target_list[target].help then
      print(target_list[target].help)
    else
      print("See texdoc l3build for more information.")
    end
    print()
  else
    help_overview()
  end
end

function help(target)
  if target then
    help_target(target)
  else
    help_overview()
  end
end