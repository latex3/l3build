--[[

File l3build-typesetting.lua Copyright (C) 2018-2023 The LaTeX Project

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

--
-- Auxiliary functions for typesetting: need to be generally available
--

local ipairs = ipairs
local pairs  = pairs
local print  = print

local gsub  = string.gsub

local os_type = os.type

function dvitopdf(name, dir, engine, hide)
  runcmd(
    set_epoch_cmd(epoch, forcecheckepoch) ..
    "dvips " .. name .. dviext
      .. (hide and (" > " .. os_null) or "")
      .. os_concat ..
    "ps2pdf " .. ps2pdfopts .. " " .. name .. psext
      .. (hide and (" > " .. os_null) or ""),
    dir
  )
end

function biber(name,dir)
  if fileexists(dir .. "/" .. name .. ".bcf") then
    return
      runcmd(biberexe .. " " .. biberopts .. " " .. name,dir,{"BIBINPUTS"})
  end
  return 0
end

function bibtex(name,dir)
  dir = dir or "."
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
      local errorlevel = runcmd(bibtexexe .. " " .. bibtexopts .. " " .. name,
        dir,{"BIBINPUTS","BSTINPUTS"})
      -- BibTeX(8) signals warnings with errorlevel 1
      if errorlevel > 1 then return errorlevel else return 0 end
    end
  end
  return 0
end

function makeindex(name,dir,inext,outext,logext,style)
  dir = dir or "."
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

function tex(file,dir,cmd)
  dir = dir or "."
  cmd = cmd or typesetexe .. " " .. typesetopts
  return runcmd(cmd .. " \"" .. typesetcmds
    .. "\\input " .. file .. "\"",
    dir,{"TEXINPUTS","LUAINPUTS"})
end

local function typesetpdf(file,dir)
  dir = dir or "."
  local name = jobname(file)
  print("Typesetting " .. name)
  local fn = typeset
  local cmd = typesetexe .. " " .. typesetopts
  if specialtypesetting and specialtypesetting[file] then
    fn = specialtypesetting[file].func or fn
    cmd = specialtypesetting[file].cmd or cmd
  end
  local errorlevel = fn(file,dir,cmd)
  if errorlevel ~= 0 then
    print(" ! Compilation failed")
    return errorlevel
  end
  return 0
end

function typeset(file,dir,exe)
  dir = dir or "."
  local errorlevel = tex(file,dir,exe)
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
      tex(file,dir,exe)
    if errorlevel ~= 0 then break end
  end
  return errorlevel
end

-- A hook to allow additional typesetting of demos
function typeset_demo_tasks()
  return 0
end

local function docinit()
  -- Set up
  dep_install(typesetdeps)
  unpack({sourcefiles, typesetsourcefiles}, {sourcefiledir, docfiledir})
  cleandir(typesetdir)
  for _,file in pairs(typesetfiles) do
    cp(file, unpackdir, typesetdir)
  end
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
  -- Main loop for doc creation
  local errorlevel = typeset_demo_tasks()
  if errorlevel ~= 0 then
    return errorlevel
  end
  return docinit_hook()
end

function docinit_hook() return 0 end

-- Typeset all required documents
-- Uses a set of dedicated auxiliaries that need to be available to others
function doc(files)
  local errorlevel = docinit()
  if errorlevel ~= 0 then return errorlevel end
  local done = {}
  for _,typesetfiles in ipairs({typesetdemofiles,typesetfiles}) do
    for _,glob in pairs(typesetfiles) do
      local destpath,globstub = splitpath(glob)
      destpath = docfiledir .. gsub(gsub(destpath,"^./",""),"^.","")
      for _,p in ipairs(tree(typesetdir,globstub)) do
        local path,srcname = splitpath(p.cwd)
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
            errorlevel = typesetpdf(srcname,path)
            if errorlevel ~= 0 then
              return errorlevel
            else
              done[name] = true
              local pdfname = jobname(srcname) .. pdfext
              rm(pdfname,destpath)
              cp(pdfname,path,destpath)
            end
          end
        end
      end
    end
  end
  return 0
end
