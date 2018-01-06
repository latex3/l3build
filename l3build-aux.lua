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

--
-- Auxiliary functions which are used by more than one main function
--

function setepoch()
  return
    os_setenv .. " SOURCE_DATE_EPOCH=" .. epoch
      .. os_concat ..
    os_setenv .. " SOURCE_DATE_EPOCH_TEX_PRIMITIVES=1"
      .. os_concat ..
    os_setenv .. " FORCE_SOURCE_DATE=1"
      .. os_concat
end

-- Do some subtarget for all modules in a bundle
function call(dirs, target, opts)
  -- Turn the option table into a string
  local opts = opts or options
  local s = ""
  for k,v in pairs(opts) do
    if k ~= "files" and k ~= "target" then -- Special cases
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
  if opts["files"] then
    for _,v in pairs(opts["files"]) do
      s = s .. " " .. v
    end
  end
  for _,i in ipairs(dirs) do
    print(
      "Running script " .. scriptname .. " with target \"" .. target
        .. "\" for module "
        .. i
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
    errorlevel = run(i, "texlua " .. scriptname .. " unpack -q")
    if errorlevel ~= 0 then
      return errorlevel
    end
  end
  return 0
end
