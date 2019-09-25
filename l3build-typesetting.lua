--[[

File l3build-typesetting.lua Copyright (C) 2018,2019 The LaTeX3 Project

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
-- Auxiliary functions for typesetting: need to be generally available
--

local ipairs = ipairs
local pairs  = pairs
local print  = print

local gsub  = string.gsub
local match = string.match

local os_type = os.type

function dvitopdf(name, dir, engine, hide)
  if match(engine, "^u?ptex$") then
    run(
      dir,
      (forcecheckepoch and setepoch() or "") ..
     "dvipdfmx  " .. name .. dviext
       .. (hide and (" > " .. os_null) or "")
    )
  else
    run(
      dir,
      (forcecheckepoch and setepoch() or "") ..
     "dvips " .. name .. dviext
       .. (hide and (" > " .. os_null) or "")
       .. os_concat ..
     "ps2pdf " .. name .. psext
        .. (hide and (" > " .. os_null) or "")
    )
  end
end

-- An auxiliary used to set up the environmental variables
function runcmd(cmd,dir,vars)
  local dir = dir or "."
  local dir = abspath(dir)
  local vars = vars or {}
  -- Allow for local texmf files
  local env = os_setenv .. " TEXMFCNF=." .. os_pathsep
  local localtexmf = ""
  if texmfdir and texmfdir ~= "" then
    localtexmf = os_pathsep .. abspath(texmfdir) .. "//"
  end
  local envpaths = "." .. os_pathsep
    .. localtexmf
    .. abspath(localdir) .. os_pathsep
    .. dir .. (typesetsearch and os_pathsep or "")
  -- Deal with spaces in paths
  if os_type == "windows" and match(envpaths," ") then
    envpaths = gsub(envpaths,'"','')
  end
  for _,var in pairs(vars) do
    env = env .. os_concat .. os_setenv .. " " .. var .. "=" .. envpaths
  end
  return run(dir,(forcedocepoch and setepoch() or "") .. env .. os_concat .. cmd)
end

function biber(name,dir)
  if fileexists(dir .. "/" .. name .. ".bcf") then
    return
      runcmd(biberexe .. " " .. biberopts .. " " .. name,dir,{"BIBINPUTS"})
  end
  return 0
end

function bibtex(name,dir)
  local dir = dir or "."
  if fileexists(dir .. "/" .. name .. ".aux") then
    -- LaTeX always generates an .aux file, so there is a need to
    -- look inside it for a \citation line
    local grep
    if os_type == "windows" then
      grep = "\\\\"
    else
     grep = "\\\\\\\\"
    end
    if run(dir,
        os_grepexe .. " \"^" .. grep .. "citation{\" " .. name .. ".aux > "
          .. os_null
      ) + run(dir,
        os_grepexe .. " \"^" .. grep .. "bibdata{\" " .. name .. ".aux > "
          .. os_null
      ) == 0 then
      return runcmd(bibtexexe .. " " .. bibtexopts .. " " .. name,dir,
        {"BIBINPUTS","BSTINPUTS"})
    end
  end
  return 0
end

function makeindex(name,dir,inext,outext,logext,style)
  local dir = dir or "."
  if fileexists(dir .. "/" .. name .. inext) then
    if style == "" then style = nil end
    return runcmd(makeindexexe .. " " .. makeindexopts
      .. " -o " .. name .. outext
      .. (style and (" -s " .. style) or "")
      .. " -t " .. name .. logext .. " "  .. name .. inext,
      dir,
      {"INDEXSTYLE"})
  end
  return 0
end

function tex(file,dir)
  local dir = dir or "."
  return runcmd(typesetexe .. " " .. typesetopts .. " \"" .. typesetcmds
    .. "\\input " .. file .. "\"",
    dir,{"TEXINPUTS","LUAINPUTS"})
end

local function typesetpdf(file,dir)
  local dir = dir or "."
  local name = jobname(file)
  print("Typesetting " .. name)
  local errorlevel = typeset(file,dir)
  if errorlevel ~= 0 then
    print(" ! Compilation failed")
    return errorlevel
  end
  pdfname = name .. pdfext
  rm(docfiledir,pdfname)
  return cp(pdfname,dir,docfiledir)
end

typeset = typeset or function(file,dir)
  dir = dir or "."
  local errorlevel = tex(file,dir)
  if errorlevel ~= 0 then
    return errorlevel
  end
  local name = jobname(file)
  errorlevel = biber(name,dir) + bibtex(name,dir)
  if errorlevel ~= 0 then
    return errorlevel
  end
  for i = 2,typesetruns do
    errorlevel =
      makeindex(name,dir,".glo",".gls",".glg",glossarystyle) +
      makeindex(name,dir,".idx",".ind",".ilg",indexstyle)    +
      tex(file,dir)
    if errorlevel ~= 0 then break end
  end
  return errorlevel
end

-- A hook to allow additional typesetting of demos
typeset_demo_tasks = typeset_demo_tasks or function()
  return 0
end

-- Typeset all required documents
-- Uses a set of dedicated auxiliaries that need to be available to others
function doc(files)
  -- Set up
  cleandir(typesetdir)
  for _,filetype in pairs(
      {bibfiles, docfiles, typesetfiles, typesetdemofiles}
    ) do
    for _,file in pairs(filetype) do
      cp(file, docfiledir, typesetdir)
    end
  end
  for _,file in pairs(sourcefiles) do
    cp(file, sourcefiledir, typesetdir)
  end
  for _,file in pairs(typesetsuppfiles) do
    cp(file, supportdir, typesetdir)
  end
  depinstall(typesetdeps)
  unpack({sourcefiles, typesetsourcefiles}, {sourcefiledir, docfiledir})
  -- Main loop for doc creation
  local errorlevel = typeset_demo_tasks()
  if errorlevel ~= 0 then
    return errorlevel
  end
  local done = {}
  for _,typesetfiles in ipairs({typesetdemofiles,typesetfiles}) do
    for _,glob in pairs(typesetfiles) do
      for _,dir in ipairs({typesetdir,unpackdir}) do
        for _,file in pairs(tree(dir,glob)) do
          local path,srcname = splitpath(file)
          local name = jobname(srcname)
          if not done[name] then
            local typeset = true
            -- Allow for command line selection of files
            if files and next(files) then
              typeset = false
              for _,file in pairs(files) do
                if name == file then
                  typeset = true
                  break
                end
              end
            end
            -- Now know if we should typeset this source
            if typeset then
              local errorlevel = typesetpdf(srcname,path)
              if errorlevel ~= 0 then
                return errorlevel
              else
                done[name] = true
              end
            end
          end
        end
      end
    end
  end
  return 0
end

