--[[

File l3build-clean.lua Copyright (C) 2018-2025 The LaTeX Project

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

local pairs   = pairs
local ipairs  = ipairs
local insert  = table.insert

-- Remove all generated files
function clean()
  -- To make sure that distribdir never contains any stray subdirs,
  -- it is entirely removed then recreated rather than simply deleting
  -- all of the files
  local errorlevel =  rmdir(distribdir)
                    + mkdir(distribdir)
                    + cleandir(localdir)
                    + cleandir(testdir)
                    + cleandir(typesetdir)
                    + cleandir(unpackdir)

  if errorlevel ~= 0 then return errorlevel end

  for _,dir in pairs(remove_duplicates({maindir,sourcefiledir,docfiledir})) do
    local clean_list  = {}
    local flags = {}
    for _,glob in pairs(cleanfiles) do
      for _,p in ipairs(tree(dir,glob)) do
        insert(clean_list, p.src)
        flags[p.src] = true
      end
    end
    for _,glob in pairs(sourcefiles) do
      for _,p in ipairs(tree(dir,glob)) do
        flags[p.src] = nil
      end
    end
    for i = #clean_list, 1, -1 do
      local p_src = clean_list[i]
      if flags[p_src] then
        errorlevel = rm(dir,p_src)
        if errorlevel ~= 0 then
          return errorlevel
        end
      end
    end
  end
  for _,i in pairs(exhibitfiles) do
    rm(currentdir, i)
  end
  return 0
end

function bundleclean()
  local errorlevel = call(modules, "clean")
  for _,i in ipairs(cleanfiles) do
    errorlevel = rm(currentdir, i) + errorlevel
  end
  return  errorlevel
        + rmdir(ctandir)
        + rmdir(tdsdir)
end
