--[[

File l3build-clean.lua Copyright (C) 2018 The LaTeX3 Project

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

-- Remove all generated files
function clean()
  -- To make sure that distribdir never contains any stray subdirs,
  -- it is entirely removed then recreated rather than simply deleting
  -- all of the files
  local errorlevel =
    rmdir(distribdir)    +
    mkdir(distribdir)    +
    cleandir(localdir)   +
    cleandir(testdir)    +
    cleandir(typesetdir) +
    cleandir(unpackdir)
  for _,i in ipairs(cleanfiles) do
    for _,dir in pairs(remove_duplicates({maindir, sourcefiledir, docfiledir})) do
      errorlevel = rm(dir, i) + errorlevel
    end
  end
  return errorlevel
end

function bundleclean()
  local errorlevel = call(modules, "clean")
  for _,i in ipairs(cleanfiles) do
    errorlevel = rm(maindir, i) + errorlevel
  end
  return (
    errorlevel     +
    rmdir(ctandir) +
    rmdir(tdsdir)
  )
end

