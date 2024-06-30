--[[

File l3build-unpack.lua Copyright (C) 2018-2024 The LaTeX Project

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

-- Unpack the package files using an 'isolated' system: this requires
-- a copy of the 'basic' DocStrip program, which is used then removed
function unpack(sources, sourcedirs)
  local errorlevel = unpack_deps(unpackdeps)
  if errorlevel ~= 0 then
    return errorlevel
  end
  errorlevel = bundleunpack(sourcedirs, sources)
  if errorlevel ~= 0 then
    return errorlevel
  end
  for _,i in ipairs(installfiles) do
    errorlevel = cp(i, unpackdir, localdir)
    if errorlevel ~= 0 then
      return errorlevel
    end
  end
  return 0
end

-- Split off from the main unpack so it can be used on a bundle and not
-- leave only one modules files
function bundleunpack(sourcedirs, sources)
  local errorlevel = mkdir(localdir)
  if errorlevel ~=0 then
    return errorlevel
  end
  errorlevel = cleandir(unpackdir)
  if errorlevel ~=0 then
    return errorlevel
  end
  for _,i in ipairs(sourcedirs or {sourcefiledir}) do
    for _,j in ipairs(sources or {sourcefiles}) do
      for _,k in ipairs(j) do
        errorlevel = cp(k, i, unpackdir)
        if errorlevel ~=0 then
          return errorlevel
        end
      end
    end
  end
  for _,i in ipairs(unpacksuppfiles) do
    errorlevel = cp(i, supportdir, localdir)
    if errorlevel ~=0 then
      return errorlevel
    end
  end
  local popen = io.popen
  for _,i in ipairs(unpackfiles) do
    for _,p in ipairs(tree(unpackdir, i)) do
      local path, name = splitpath(p.src)
      local localdir = abspath(localdir)
      local success = assert(popen(
        "cd " .. unpackdir .. "/" .. path .. os_concat ..
        os_setenv .. " TEXINPUTS=." .. os_pathsep
          .. localdir .. (unpacksearch and os_pathsep or "") ..
        os_concat  ..
        os_setenv .. " LUAINPUTS=." .. os_pathsep
          .. localdir .. (unpacksearch and os_pathsep or "") ..
        os_concat ..
        unpackexe .. " " .. unpackopts .. " " .. name
          .. (options["quiet"] and (" > " .. os_null) or ""),
        "w"
      ):write(string.rep("y\n", 300))):close()
      if not success then
        return 1
      end
    end
  end
  return 0
end
