--[[

File l3build-ctan.lua Copyright (C) 2018 The LaTeX3 Project

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

local gsub             = string.gsub
local match            = string.match
local insert           = table.insert

-- Copy files to the main CTAN release directory
function copyctan()
  mkdir(ctandir .. "/" .. ctanpkg)
  local function copyfiles(files,source)
    if source == currentdir or flatten then
      for _,filetype in pairs(files) do
        cp(filetype,source,ctandir .. "/" .. ctanpkg)
      end
    else
      for _,filetype in pairs(files) do
        for file,_ in pairs(tree(source,filetype)) do
          local path = splitpath(file)
          local ctantarget = ctandir .. "/" .. ctanpkg .. "/"
            .. source .. "/" .. path
          mkdir(ctantarget)
          cp(file,source,ctantarget)
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
    cp(file, currentdir, ctandir .. "/" .. ctanpkg)
  end
end

-- Copy files to the correct places in the TDS tree
function copytds()
  local function install(source, dest, files, tool)
    local moduledir = moduledir
    -- For material associated with secondary tools (BibTeX, MakeIndex)
    -- the structure needed is slightly different from those items going
    -- into the tex/doc/source trees
    if tool then
      -- "base" is reserved for the tools themselves: make the assumption
      -- in this case that the tdsroot name is the right place for stuff to
      -- go (really just for the team)
      if module == "base" then
        moduledir = tdsroot
      else
        moduledir = module
      end
    end
    -- Convert the file table(s) to a list of individual files
    local filenames = { }
    for _,i in ipairs(files) do
      for _,j in ipairs(i) do
        for file,_ in pairs(tree(source, j)) do
          insert(filenames, file)
        end
      end
    end
    -- The target is only created if there are actual files to install
    if next(filenames) ~= nil then
      local installdir = tdsdir .. "/" .. dest .. "/" .. moduledir
      mkdir(installdir)
      for _,i in ipairs(filenames) do
        cp(i, source, installdir)
      end
    end
  end
  install(
    docfiledir,
    "doc",
    {bibfiles, demofiles, docfiles, pdffiles, textfiles, typesetlist}
  )
  install(unpackdir, "makeindex", {makeindexfiles}, true)
  install(unpackdir, "bibtex/bst", {bstfiles}, true)
  install(sourcefiledir, "source", {sourcelist})
  install(unpackdir, "tex", {installfiles})
  install(unpackdir, "scripts", {scriptfiles}, true)
  -- Any script man files need special handling
  for _,glob in pairs(scriptmanfiles) do
    for file,_ in pairs(tree(docfiledir,glob)) do
      -- Man files should have a single-digit extension: the type
      local installdir = tdsdir .. "/doc/man/man"  .. match(file,".$")
      mkdir(installdir)
      cp(file,docfiledir,installdir)
    end
  end
end

-- Standard versions of the main targets for building modules

function ctan()
  -- Always run tests for all engines
  options["engine"] = nil
  local function dirzip(dir, name)
    local zipname = name .. ".zip"
    local function tab_to_str(table)
      local string = ""
      for _,i in ipairs(table) do
        string = string .. " " .. "\"" .. i .. "\""
      end
      return string
    end
    -- Convert the tables of files to quoted strings
    local binfiles = tab_to_str(binaryfiles)
    local exclude = tab_to_str(excludefiles)
    -- First, zip up all of the text files
    run(
      dir,
      zipexe .. " " .. zipopts .. " -ll ".. zipname .. " " .. "."
        .. (
          (binfiles or exclude) and (" -x" .. binfiles .. " " .. exclude)
          or ""
        )
    )
    -- Then add the binary ones
    run(
      dir,
      zipexe .. " " .. zipopts .. " -g ".. zipname .. " " .. ". -i" ..
        binfiles .. (exclude and (" -x" .. exclude) or "")
    )
  end
  local errorlevel
  local standalone = false
  if bundle == "" then
    standalone = true
  end
  if standalone then
    errorlevel = check()
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
      errorlevel = bundlectan()
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
      for _,j in pairs({unpackdir, currentdir}) do
        cp(i, j, ctandir .. "/" .. ctanpkg)
        cp(i, j, tdsdir .. "/doc/" .. tdsroot .. "/" .. bundle)
      end
    end
    dirzip(tdsdir, ctanpkg .. ".tds")
    if packtdszip then
      cp(ctanpkg .. ".tds.zip", tdsdir, ctandir)
    end
    dirzip(ctandir, ctanpkg)
    cp(ctanpkg .. ".zip", ctandir, currentdir)
  else
    print("\n====================")
    print("Typesetting failed, zip stage skipped!")
    print("====================\n")
  end
  return errorlevel
end

function bundlectan()
  -- Generate a list of individual file names excluding those in the second
  -- argument: the latter is a table
  local function excludelist(include, exclude, dir)
    local include = include or { }
    local exclude = exclude or { }
    local dir = dir or currentdir
    local includelist = { }
    local excludelist = { }
    for _,i in ipairs(exclude) do
      for _,j in ipairs(i) do
        for file,_ in pairs(tree(dir, j)) do
          excludelist[file] = true
        end
      end
    end
    for _,i in ipairs(include) do
      for file,_ in pairs(tree(dir, i)) do
        if not excludelist[file] then
          insert(includelist, file)
        end
      end
    end
    return includelist
  end
  unpack()
  local errorlevel = doc()
  if errorlevel == 0 then
    -- Work out what PDF files are available
    pdffiles = { }
    for _,i in ipairs(typesetfiles) do
      insert(pdffiles, (gsub(i, "%.%w+$", ".pdf")))
    end
    -- For the purposes here, any typesetting demo files need to be
    -- part of the main typesetting list
    local typesetfiles = typesetfiles
    for _,v in pairs(typesetdemofiles) do
      insert(typesetfiles, v)
    end
    typesetlist = excludelist(typesetfiles, {sourcefiles}, docfiledir)
    sourcelist = excludelist(
      sourcefiles, {bstfiles, installfiles, makeindexfiles, scriptfiles},
      sourcefiledir
    )
    copyctan()
    copytds()
  end
  return errorlevel
end

