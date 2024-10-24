--[[

File l3build-ctan.lua Copyright (C) 2018-2024 The LaTeX Project

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

local pairs = pairs
local print = print

local attributes = lfs.attributes
local lower = string.lower
local match = string.match

local newzip = require"l3build-zip"

-- Copy files to the main CTAN release directory
function copyctan()
  local pkgdir = ctandir .. "/" .. ctanpkg
  mkdir(pkgdir)

  -- Handle pre-formed sources: do two passes to avoid any cleandir() issues
  for _,dest in pairs(tdsdirs) do
    mkdir(pkgdir .. "/" .. dest)
  end
  for src,dest in pairs(tdsdirs) do
    cp("*",src,pkgdir .. "/" .. dest)
  end

  -- Now deal with the one-at-a-time files
  local function copyfiles(files,source)
    if source == currentdir or flatten then
      for _,filetype in pairs(files) do
        cp(filetype,source,pkgdir)
      end
    else
      for _,filetype in pairs(files) do
        for _,p in ipairs(tree(source,filetype)) do
          local path = dirname(p.src)
          local ctantarget = pkgdir .. "/"
            .. source .. "/" .. path
          mkdir(ctantarget)
          cp(p.src,source,ctantarget)
        end
      end
    end
  end
  for _,tab in pairs(
    {bibfiles,demofiles,docfiles,pdffiles,scriptmanfiles,typesetlist}) do
    copyfiles(tab,docfiledir)
  end
  copyfiles(sourcefiles,sourcefiledir)
  for _,file in pairs(textfiles) do
    cp(file, textfiledir, pkgdir)
  end

end

function bundlectan()
  local errorlevel = install_files(tdsdir,true)
  if errorlevel ~=0 then return errorlevel end
  copyctan()
  return 0
end

function ctan()
  -- Always run tests for all engines
  options["engine"] = nil
  local function dirzip(dir, zipname)
    zipname = zipname .. ".zip"
    local zip = assert(newzip(dir .. '/' .. zipname))
    local function tab_to_check(table)
      local patterns = {}
      for n,i in ipairs(table) do
        patterns[n] = glob_to_pattern(i)
      end
      return function(name)
        for n, patt in ipairs(patterns) do
          if name:match"([^/]*)$":match(patt) then return true end
        end
        return false
      end
    end
    -- Convert the tables of files to quoted strings
    local binfile = tab_to_check(binaryfiles)
    local exclude = tab_to_check(excludefiles)
    local exefile = tab_to_check(exefiles)
    -- First, zip up all of the text files
    for _, p in ipairs(tree(dir, "**")) do
      local src = p.src:sub(3) -- Strip ./
      if not (attributes(p.cwd, "mode") == "directory" or exclude(src) or src == zipname) then
        zip:add(p.cwd, src, binfile(src), exefile(src))
      end
    end
    return zip:close()
  end
  local errorlevel
  local standalone = false
  if bundle == "" then
    standalone = true
  end
  if standalone then
    errorlevel = call({"."},"check")
    bundle = module
  else
    errorlevel = call(modules, "bundlecheck")
  end
  if errorlevel == 0 then
    rmdir(ctandir)
    mkdir(ctandir .. "/" .. ctanpkg)
    rmdir(tdsdir)
    mkdir(tdsdir)
    if standalone then
      errorlevel = install_files(tdsdir,true)
      if errorlevel ~=0 then return errorlevel end
      copyctan()
    else
      errorlevel = call(modules, "bundlectan")
    end
  else
    print("\n====================")
    print("Tests failed, zip stage skipped!")
    print("====================\n")
    return errorlevel
  end
  if errorlevel == 0 then
    for _,i in ipairs(textfiles) do
      for _,j in pairs({unpackdir, textfiledir}) do
        cp(i, j, ctandir .. "/" .. ctanpkg)
        cp(i, j, tdsdir .. "/doc/" .. tdsroot .. "/" .. bundle)
      end
    end
    -- Rename README if necessary
    if ctanreadme ~= "" and not match(lower(ctanreadme),"^readme$") and
      not match(lower(ctanreadme),"^readme%.%w+") then
      local newfile = "README." .. match(ctanreadme,"%.(%w+)$")
      for _,dir in pairs({ctandir .. "/" .. ctanpkg,
        tdsdir .. "/doc/" .. tdsroot .. "/" .. bundle}) do
        if fileexists(dir .. "/" .. ctanreadme) then
          rm(dir,newfile)
          ren(dir,ctanreadme,newfile)
        end
      end
    end
    dirzip(tdsdir, ctanpkg .. ".tds")
    if packtdszip then
      cp(ctanpkg .. ".tds.zip", tdsdir, ctandir)
      cp(ctanpkg .. ".tds.zip", tdsdir, currentdir)
    end
    dirzip(ctandir, ctanzip)
    cp(ctanzip .. ".zip", ctandir, currentdir)
  else
    print("\n====================")
    print("Typesetting failed, zip stage skipped!")
    print("====================\n")
  end
  return errorlevel
end
