--[[

File l3build-typesetting.lua Copyright (C) 2018-2026 The LaTeX Project

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
local match = string.match

local open    = io.open
local os_type = os.type

function dvitopdf(name, dir, engine, hide)
  local env = add_tex_env_vars({}, dir, {})
  
  local cmd = {
      "dvips",
      name .. dviext,
  }
  local errorlevel, output = execute(dir, cmd, env)
  if not hide then print(output) end
  if errorlevel ~= 0 then return errorlevel end

  cmd = {"ps2pdf"}
  append_option_string_to_array(cmd, ps2pdfopts)
  cmd[#cmd + 1] = name .. psext
  errorlevel, output = execute(dir, cmd, env)

  if not hide then print(output) end
  return errorlevel
end

function biber(name,dir)
  if fileexists(dir .. "/" .. name .. ".bcf") then
    local env = add_tex_env_vars({}, dir, {"BIBINPUTS"})
    local cmd = {biberexe}
    append_option_string_to_array(cmd, biberopts)
    cmd[#cmd + 1] = name
    local errorlevel, output = execute(dir, cmd, env)
    print(output)
    return errorlevel
  end
  return 0
end

function bibtex(name,dir)
  dir = dir or "."
  if fileexists(dir .. "/" .. name .. ".aux") then
    local f = open(dir .. "/" .. name .. ".aux","r")
    if not f then return 0 end
    local auxdata = f:read("a")
    f:close()

    if (
      not auxdata:match([[\\citation{]]) and
      not auxdata:match([[\\bibdata{]])
    ) then
      return 0
    end

    local env = add_tex_env_vars({}, dir, {"BIBINPUTS", "BSTINPUTS"})
    local cmd = {bibtexexe}
    append_option_string_to_array(cmd, bibtexopts)
    cmd[#cmd + 1] = name
    local errorlevel, output = execute(dir, cmd, env)

    print(output)
    if errorlevel > 1 then
      return errorlevel
    else
      return 0
    end
  end
  return 0
end

function makeindex(name,dir,inext,outext,logext,style)
  dir = dir or "."
  if fileexists(dir .. "/" .. name .. inext) then
    local env = add_tex_env_vars({}, dir, {"INDEXSTYLE"})
    local cmd = {makeindexexe}
    append_option_string_to_array(cmd, makeindexopts)
    cmd[#cmd + 1] = "-o"
    cmd[#cmd + 1] = name .. outext
    if style and style ~= "" then
      cmd[#cmd + 1] = "-s"
      cmd[#cmd + 1] = style
    end
    cmd[#cmd + 1] = "-t"
    cmd[#cmd + 1] = name .. logext
    cmd[#cmd + 1] = name .. inext

    local errorlevel, output = execute(dir, cmd, env)
    print(output)
    return errorlevel
  end
  return 0
end

function tex(file,dir,exe)
  dir = dir or "."

  local env = add_tex_env_vars({}, dir, {"TEXINPUTS", "LUAINPUTS"})
  local cmd = append_option_string_to_array({}, exe or typesetexe)
  append_option_string_to_array(cmd, typesetopts)
  cmd[#cmd + 1] = ([[%s\input{%s}]]):format(typesetcmds, file)

  local errorlevel, output = execute(dir, cmd, env)
  print(table.unpack(cmd))
  print(output)
  return errorlevel
end

-- Scan the typeset log for overfull/underfull boxes: these are reported
-- by the engine itself and cannot be trapped at the TeX level (except by
-- the LuaTeX callbacks), so the builder is the only place to catch them
local function checkbadboxes(file,dir)
  local logfile = open(dir .. "/" .. jobname(file) .. ".log","r")
  if not logfile then
    return 0
  end
  local boxes = 0
  for line in logfile:lines() do
    if match(line,"^Overfull ") or match(line,"^Underfull ") then
      print(line)
      boxes = boxes + 1
    end
  end
  logfile:close()
  if boxes > 0 then
    print(" ! " .. boxes .. " bad box(es) found in the typeset log")
    return 1
  end
  return 0
end

local function typesetpdf(file,dir)
  dir = dir or "."
  local name = jobname(file)
  print("Typesetting " .. name)
  local fn = typeset
  local cmd = typesetexe .. " " .. typesetopts
  for glob,v in pairs(specialtypesetting) do
    if match(file,glob_to_pattern(glob)) then
      fn = v.func or fn
      cmd = v.cmd or cmd
      break
    end
  end
  local errorlevel = fn(file,dir,cmd)
  if errorlevel ~= 0 then
    print(" ! Compilation failed")
    return errorlevel
  end
  if typesetwarnings then
    return checkbadboxes(file,dir)
  end
  return 0
end

function typeset(file,dir,exe)
  dir = dir or "."
  local name = jobname(file)
  
  local errorlevel = tex(file,dir,exe)
  if errorlevel ~= 0 then print("tex failed") return errorlevel end

  errorlevel = biber(name,dir)
  if errorlevel ~= 0 then print("biber failed") return errorlevel end

  errorlevel = bibtex(name,dir)
  if errorlevel ~= 0 then print("bibtex failed") return errorlevel end

  for i = 2,typesetruns do
    errorlevel = makeindex(name,dir,".glo",".gls",".glg",glossarystyle)
    if errorlevel ~= 0 then print("glossaries failed") break end

    errorlevel = makeindex(name,dir,".idx",".ind",".ilg",indexstyle)
    if errorlevel ~= 0 then print("indexing failed") break end

    errorlevel = tex(file,dir,exe)
    if errorlevel ~= 0 then print("tex failed") break end
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
  local errorlevel = 0
  if not options["rerun"] then
    errorlevel = docinit()
  end
  if errorlevel ~= 0 then return errorlevel end
  local done = {}
  local files_unknown = {}
  if files and next(files) then
    for _, file in pairs(files) do
      files_unknown[file] = true
    end
  end
  for _,typesetfiles in ipairs({typesetdemofiles,typesetfiles}) do
    for _,glob in pairs(typesetfiles) do
      local destpath,globstub = splitpath(glob)
      destpath = docfiledir .. gsub(gsub(destpath,"^%./",""),"^%.","")
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
                files_unknown[file] = nil
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
  if next(files_unknown) then
    for file, _ in pairs(files_unknown) do
      print("Unknown doc name \"" .. file .. "\"")
    end
    return 1
  end
  return 0
end
