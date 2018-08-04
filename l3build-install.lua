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

local match = string.match

local insert = table.insert

local function gethome()
  set_program("latex")
  return options["texmfhome"] or var_value("TEXMFHOME")
end

function uninstall()
  local function uninstall_files(dir,subdir)
    subdir = subdir or moduledir
    dir = dir .. "/" .. subdir
    local installdir = gethome() .. "/" .. dir
    if options["dry-run"] then
      local files = filelist(installdir)
      if next(files) then
        print("\n" .. "For removal from " .. installdir .. ":")
        for _,file in pairs(filelist(installdir)) do
          print("- " .. file)
        end
      end
      return 0
    else
      if direxists(installdir) then
        return rmdir(installdir)
      end
    end
    return 0
  end
  local errorlevel = 0
  -- Any script man files need special handling
  local manfiles = { }
  for _,glob in pairs(scriptmanfiles) do
    for file,_ in pairs(tree(docfiledir,glob)) do
      -- Man files should have a single-digit extension: the type
      local installdir = gethome() .. "/doc/man/man"  .. match(file,".$")
      if fileexists(installdir .. "/" .. file) then
        if options["dry-run"] then
          insert(manfiles,"man" .. match(file,".$") .. "/" ..
           select(2,splitpath(file)))
        else
          errorlevel = errorlevel + rm(installdir,file)
        end
      end
    end
  end
  if next(manfiles) then
    print("\n" .. "For removal from " .. gethome() .. "/doc/man:")
    for _,v in ipairs(manfiles) do
      print("- " .. v)
    end
  end
  return   uninstall_files("doc")
         + uninstall_files("source")
         + uninstall_files("tex")
         + uninstall_files("bibtex/bst",module)
         + uninstall_files("makeindex",module)
         + uninstall_files("scripts",module)
         + errorlevel
end

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
