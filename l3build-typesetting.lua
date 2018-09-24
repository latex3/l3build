--[[

File l3build-typesetting.lua Copyright (C) 2018 The LaTeX3 Project

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

local gsub             = string.gsub
local match            = string.match

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
function runtool(subdir, dir, envvar, command)
  set_program_name("kpsewhich")
  dir = dir or "."
  return(
    run(
      typesetdir .. "/" .. subdir,
      (forcedocepoch and setepoch() or "") ..
      -- Allow for local texmf files
      os_setenv .. " TEXMFCNF=." .. os_pathsep
        .. os_concat ..
      os_setenv .. " " .. envvar .. "=." .. os_pathsep
        .. abspath(localdir) .. os_pathsep
        .. abspath(dir .. "/" .. subdir)
        .. (typesetsearch and os_pathsep or "")
        .. os_concat ..
      command
    )
  )
end

function biber(name, dir)
  if fileexists(typesetdir .. "/" .. name .. ".bcf") then
    local path, name = splitpath(name)
    return(
      runtool(path, dir, "BIBINPUTS",  biberexe .. " " .. biberopts .. " " .. name)
    )
  end
  return 0
end

function bibtex(name, dir)
  if fileexists(typesetdir .. "/" .. name .. ".aux") then
    -- LaTeX always generates an .aux file, so there is a need to
    -- look inside it for a \citation line
    local grep
    if os_type == "windows" then
      grep = "\\\\"
    else
     grep = "\\\\\\\\"
    end
    local path, name = splitpath(name)
    if run(
        typesetdir,
        os_grepexe .. " \"^" .. grep .. "citation{\" " .. name .. ".aux > "
          .. os_null
      ) + run(
        typesetdir,
        os_grepexe .. " \"^" .. grep .. "bibdata{\" " .. name .. ".aux > "
          .. os_null
      ) == 0 then
      return(
        -- Cheat slightly as we need to set two variables
        runtool(
          path, dir,
          "BIBINPUTS",
          os_setenv .. " BSTINPUTS=." .. os_pathsep
            .. abspath(localdir)
            .. (typesetsearch and os_pathsep or "") ..
          os_concat ..
          bibtexexe .. " " .. bibtexopts .. " " .. name
        )
      )
    end
  end
  return 0
end

function makeindex(name, dir, inext, outext, logext, style)
  if fileexists(typesetdir .. "/" .. name .. inext) then
    local path, name = splitpath(name)
    if style == "" then style = nil end
    return(
      runtool(
        path, dir,
        "INDEXSTYLE",
        makeindexexe .. " " .. makeindexopts
          .. " -o " .. name .. outext
          .. (style and (" -s " .. style) or "")
          .. " -t " .. name .. logext .. " "  .. name .. inext
      )
    )
  end
  return 0
end

function tex(file, dir)
  local path, name = splitpath(file)
  return(
    runtool(
      path, dir,
      "TEXINPUTS",
      typesetexe .. " " .. typesetopts .. " \"" .. typesetcmds
        .. "\\input " .. name .. "\""
    )
  )
end

function typesetpdf(file, dir)
  local name = gsub(file, "%.[^.]+$", "")
  print("Typesetting " .. name)
  local errorlevel = typeset(file, dir)
  if errorlevel == 0 then
    name = name .. ".pdf"
    os.remove(jobname(name))
    cp(name, typesetdir, docfiledir)
  else
    print(" ! Compilation failed")
  end
  return errorlevel
end

typeset = typeset or function(file, dir)
  dir = dir or "."
  local errorlevel = tex(file, dir)
  if errorlevel ~= 0 then
    return errorlevel
  else
    local name = jobname(file)
    errorlevel = biber(name, dir) + bibtex(name, dir)
    if errorlevel == 0 then
      local function cycle(name, dir)
        return(
          makeindex(name, dir, ".glo", ".gls", ".glg", glossarystyle) +
          makeindex(name, dir, ".idx", ".ind", ".ilg", indexstyle)    +
          tex(file, dir)
        )
      end
      for i = 1, typesetruns do
        errorlevel = cycle(name, dir)
        if errorlevel ~= 0 then break end
      end
    end
    return errorlevel
  end
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
  local done = {}
  local errorlevel = typeset_demo_tasks()
  if errorlevel ~= 0 then
    return errorlevel
  end
  for _, typesetfiles in ipairs({typesetdemofiles, typesetfiles}) do
    for _,i in ipairs(typesetfiles) do
      for _, dir in ipairs({unpackdir, typesetdir}) do
        for j,_ in pairs(tree(dir, i)) do
          if not done[j] then
            j = gsub(j, "^%./", "")
            -- Allow for command line selection of files
            local typeset = true
            if files and next(files) then
              typeset = false
              for _,k in ipairs(files) do
                if k == gsub(j, "%.[^.]+$", "") then
                  typeset = true
                  break
                end
              end
            end
            if typeset then
              local errorlevel = typesetpdf(j, dir)
              if errorlevel ~= 0 then
                return errorlevel
              else
                done[j] = true
              end
            end
          end
        end
      end
    end
  end
  return 0
end
