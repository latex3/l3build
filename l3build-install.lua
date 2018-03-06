--[[

File l3build-install.lua Copyright (C) 2018 The LaTeX3 Project

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

local pairs = pairs
local print = print

local set_program = kpse.set_program_name
local var_value   = kpse.var_value

local function gethome()
  set_program("latex")
  return options["texmfhome"] or var_value("TEXMFHOME")
end

function uninstall()
  local function uninstall_files(target)
    local installdir = gethome() .. target
    if options["dry-run"] then
      print("\n" .. "Installation root: " .. installdir)
      local files = filelist(installdir)
      -- Deal with an empty directory
      if next(files) then
        print("\n" .. "Files for removal:")
        for _,file in pairs(filelist(installdir)) do
          print("- " .. file)
        end
      else
        print("No files present")
      end
      return 0
    else
      return rmdir(installdir)
    end
  end
  return   uninstall_files("/tex/" .. moduledir)
         + uninstall_files("/scripts/" .. module)
end


-- Locally install files: only deals with those extracted, not docs etc.
function install()
  local function install_files(files,target)
    if not next(files) then
      return 0
    end
    local installdir = gethome() .. target
    if options["dry-run"] then
      print("\n" .. "Installation root: " .. installdir
        .. "\n" .. "Installation files:"
      )
      for _,filetype in pairs(files) do
        for _,file in pairs(filelist(unpackdir,filetype)) do
          print("- " .. file)
        end
      end
      return 0
    else
      errorlevel = cleandir(installdir)
      if errorlevel ~= 0 then
        return errorlevel
      end
      for _,filetype in pairs(files) do
        errorlevel = cp(filetype, unpackdir, installdir)
        if errorlevel ~= 0 then
          return errorlevel
        end
      end
    end
    return 0
  end
  local errorlevel = unpack()
  if errorlevel ~= 0 then
    return errorlevel
  end
  return   install_files(installfiles, "/tex/" .. moduledir)
         + install_files(scriptfiles, "/scripts/" .. module)
end
