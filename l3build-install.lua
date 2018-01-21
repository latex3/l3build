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


-- Locally install files: only deals with those extracted, not docs etc.
function install()
  local errorlevel = unpack()
  if errorlevel ~= 0 then
    return errorlevel
  end
  kpse.set_program_name("latex")
  local texmfhome = options["texmfhome"] or kpse.var_value("TEXMFHOME")
  local installdir = texmfhome .. "/tex/" .. moduledir
  if options["dry-run"] then
    print("\n" .. "Installation root: " .. installdir
      .. "\n" .. "Installation files:"
    )
    for _,filetype in ipairs(installfiles) do
      for _,file in pairs(filelist(unpackdir,filetype)) do
        print("- " .. file)
      end
    end
  else
    errorlevel = cleandir(installdir)
    if errorlevel ~= 0 then
      return errorlevel
    end
    for _,filetype in ipairs(installfiles) do
      errorlevel = cp(filetype, unpackdir, installdir)
      if errorlevel ~= 0 then
        return errorlevel
      end
    end
  end
  return 0
end
