--[[

File l3build-stdmain.lua Copyright (C) 2018 The LaTeX3 Project

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

local exit             = os.exit

-- List all modules
function listmodules()
  local modules = { }
  local exclmodules = exclmodules or { }
  for entry in lfs.dir(".") do
    if entry ~= "." and entry ~= ".." then
      local attr = lfs.attributes(entry)
      assert(type(attr) == "table")
      if attr.mode == "directory" then
        if not exclmodules[entry] then
          table.insert(modules, entry)
        end
      end
    end
  end
  return modules
end

--
-- The overall main function
--

function stdmain(target, names)
  local errorlevel
  -- If the module name is empty, the script is running in a bundle:
  -- apart from ctan all of the targets are then just mappings
  if module == "" then
    -- Detect all of the modules
    modules = modules or listmodules()
    if target == "doc" then
      errorlevel = call(modules, "doc")
    elseif target == "check" then
      errorlevel = call(modules, "bundlecheck")
      if errorlevel ~=0 then
        print("There were errors: checks halted!\n")
      end
    elseif target == "clean" then
      errorlevel = bundleclean()
    elseif target == "ctan" then
      errorlevel = ctan()
    elseif target == "install" then
      errorlevel = call(modules, "install")
    elseif target == "setversion" then
      errorlevel = call(modules, "setversion")
      -- Deal with any files in the bundle dir itself
      if errorlevel == 0 then
        errorlevel = setversion()
      end
    elseif target == "uninstall" then
      errorlevel = call(modules, "uninstall")
    elseif target == "unpack" then
      errorlevel = call(modules, "bundleunpack")
    elseif target == "version" then
      version()
    else
      help()
    end
  else
    if target == "bundleunpack" then -- 'Hidden' as only needed 'higher up'
      depinstall(unpackdeps)
      errorlevel = bundleunpack()
    elseif target == "bundlecheck" then
      errorlevel = check()
    elseif target == "bundlectan" then
      errorlevel = bundlectan()
    elseif target == "doc" then
      errorlevel = doc(names)
    elseif target == "check" then
      errorlevel = check(files)
    elseif target == "clean" then
      errorlevel = clean()
    elseif target == "ctan" then
      errorlevel = ctan()
    elseif target == "install" then
      errorlevel = install()
    elseif target == "manifest" then
      errorlevel = manifest()
    elseif target == "save" then
      if next(files) then
        errorlevel = save(files)
      else
        help()
      end
    elseif target == "setversion" then
      errorlevel = setversion()
    elseif target == "uninstall" then
      errorlevel = uninstall()
    elseif target == "unpack" then
      errorlevel = unpack()
    elseif target == "version" then
      version()
    else
      help()
    end
  end
  if errorlevel ~= 0 then
    exit(1)
  else
    exit(0)
  end
end
