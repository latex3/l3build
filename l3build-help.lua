--[[

File l3build-help.lua Copyright (C) 2018 The LaTeX3 Project

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

function version()
  print(
    "\n" ..
    "l3build: A testing and building system for LaTeX\n\n" ..
    "Release " .. release_date
  )
end

function help()
  print("usage: " .. arg[0] .. " <command> [<options>] [<names>]")
  print("")
  print("The most commonly used l3build commands are:")
  if testfiledir ~= "" then
    print("   check      Run all automated tests")
  end
  print("   clean      Clean out directory tree")
  if module == "" or bundle == "" then
    print("   ctan       Create CTAN-ready archive")
  end
  print("   doc        Typesets all documentation files")
  print("   install    Installs files into the local texmf tree")
  if module ~= "" and testfiledir ~= "" then
    print("   save       Saves test validation log")
  end
  print("   setversion Update version information in sources")
  print("   unpack     Unpacks the source files into the build tree")
  print("")
  print("Valid options are:")
  local longest = 0
  for k,v in pairs(option_list) do
    if k:len() > longest then
      longest = k:len()
    end
  end
  -- Sort the options
  local t = { }
  for k,_ in pairs(option_list) do
    table.insert(t, k)
  end
  table.sort(t)
  for _,k in ipairs(t) do
    local opt = option_list[k]
    local filler = string.rep(" ", longest - k:len() + 1)
    if opt["desc"] then -- Skip --help as it has no desc
      if opt["short"] then
        print("   --" .. k .. "|-" .. opt["short"] .. filler .. opt["desc"])
      else
        print("   --" .. k .. "   " .. filler .. opt["desc"])
      end
    end
  end
  print("")
  print("See l3build.pdf for further details.")
end
