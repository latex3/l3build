--[[

File l3build-check.lua Copyright (C) 2018 The LaTeX3 Project

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

-- Local access to functions
local open             = io.open
local close            = io.close
local write            = io.write
local output           = io.output

local rnd              = math.random

local luatex_version   = status.luatex_version

local len              = string.len
local char             = string.char
local format           = string.format
local gmatch           = string.gmatch
local gsub             = string.gsub
local match            = string.match

local insert           = table.insert
local sort             = table.sort

local utf8_char        = unicode.utf8.char

local exit             = os.exit
local execute          = os.execute

--
-- Auxiliary functions which are used by more than one main function
--

-- Set up the check system files: needed for checking one or more tests and
-- for saving the test files
function checkinit()
  cleandir(testdir)
  depinstall(checkdeps)
  -- Copy dependencies to the test directory itself: this makes the paths
  -- a lot easier to manage, and is important for dealing with the log and
  -- with file input/output tests
  for _,i in ipairs(filelist(localdir)) do
    cp(i, localdir, testdir)
  end
  bundleunpack({sourcefiledir, testfiledir})
  for _,i in ipairs(installfiles) do
    cp(i, unpackdir, testdir)
  end
  for _,i in ipairs(checkfiles) do
    cp(i, unpackdir, testdir)
  end
  if direxists(testsuppdir) then
    for _,i in ipairs(filelist(testsuppdir)) do
      cp(i, testsuppdir, testdir)
    end
  end
  for _,i in ipairs(checksuppfiles) do
    cp(i, supportdir, testdir)
  end
  execute(os_ascii .. ">" .. testdir .. "/ascii.tcx")
end

-- Convert the raw log file into one for comparison/storage: keeps only
-- the 'business' part from the tests and removes system-dependent stuff
local function formatlog(logfile, newfile, engine, errlevels)
  local maxprintline = maxprintline
  if engine == "luatex" or engine == "luajittex" then
    maxprintline = maxprintline + 1 -- Deal with an out-by-one error
  end
  local function killcheck(line)
      -- Skip lines containing file dates
      if match(line, "[^<]%d%d%d%d/%d%d/%d%d") then
        return true
      elseif
      -- Skip \openin/\openout lines in web2c 7.x
      -- As Lua doesn't allow "(in|out)", a slightly complex approach:
      -- do a substitution to check the line is exactly what is required!
        match(
          gsub(line, "^\\openin", "\\openout"), "^\\openout%d%d? = "
        ) then
        return true
      end
    return false
  end
    -- Substitutions to remove some non-useful changes
  local function normalize(line, lastline)
    -- Zap line numbers from \show, \showbox, \box_show and the like:
    -- do this before wrapping lines
    line = gsub(line, "^l%.%d+ ", "l. ...")
    -- Also from lua stack traces.
    line = gsub(line, "lua:%d+: in function", "lua:...: in function")
    -- Allow for wrapped lines: preserve the content and wrap
    -- Skip lines that have an explicit marker for truncation
    if len(line) == maxprintline  and
       not match(line, "%.%.%.$") then
      return "", (lastline or "") .. line
    end
    local line = (lastline or "") .. line
    lastline = ""
    -- Zap ./ at begin of filename
    line = gsub(line, "%(%.%/", "(")
    -- Zap paths if places other than 'here' are accessible
    if checksearch then
      -- The pattern excludes < and > as the image part can have
      -- several entries on one line
      local pattern = "%w?:?/[^ %<%>]*/([^/%(%)]*%.%w*)"
      -- Files loaded from TeX: all start ( -- )
      line = gsub(line, "%(" .. pattern, "(../%1")
      -- Images
      line = gsub(line, "<" .. pattern .. ">", "<../%1>")
      -- luaotfload files start with keywords
      line = gsub(line, "from " .. pattern .. "%(", "from. ./%1(")
      line = gsub(line, ": " .. pattern .. "%)", ": ../%1)")
      -- Deal with XeTeX specials
      if match(line, "^%.+\\XeTeX.?.?.?file") then
        line = gsub(line, pattern, "../%1")
      end
    end
    -- Deal with the fact that "(.aux)" may have still a leading space
    line = gsub(line, "^ %(%.aux%)", "(.aux)")
    -- Merge all of .fd data into one line so will be removed later
    if match(line, "^ *%([%.%/%w]+%.fd[^%)]*$") then
      lastline = (lastline or "") .. line
      return "", (lastline or "") .. line
    end
    -- TeX90/XeTeX knows only the smaller set of dimension units
    line = gsub(line,
      "cm, mm, dd, cc, bp, or sp",
      "cm, mm, dd, cc, nd, nc, bp, or sp")
    -- On the other hand, (u)pTeX has some new units!
    line = gsub(line,
      "em, ex, zw, zh, in, pt, pc,",
      "em, ex, in, pt, pc,")
    line = gsub(line,
      "cm, mm, dd, cc, bp, H, Q, or sp;",
      "cm, mm, dd, cc, nd, nc, bp, or sp;")
    -- Normalise a case where fixing a TeX bug changes the message text
    line = gsub(line, "\\csname\\endcsname ", "\\csname\\endcsname")
    -- Zap "on line <num>" and replace with "on line ..."
    -- Two similar cases, Lua patterns mean we need to do them separately
    line = gsub(line, "on line %d*", "on line ...")
    line = gsub(line, "on input line %d*", "on input line ...")
    -- Tidy up to ^^ notation
    for i = 0, 31 do
      line = gsub(line, char(i), "^^" .. char(64 + i))
    end
    -- Normalise register allocation to hard-coded numbers
    -- No regex, so use a pattern plus lookup approach
    local register_types = {
        attribute      = true,
        box            = true,
        bytecode       = true,
        catcodetable   = true,
        count          = true,
        dimen          = true,
        insert         = true,
        language       = true,
        luabytecode    = true,
        luachunk       = true,
        luafunction    = true,
        marks          = true,
        muskip         = true,
        read           = true,
        skip           = true,
        toks           = true,
        whatsit        = true,
        write          = true,
        XeTeXcharclass = true
      }
    if register_types[match(line, "^\\[^%]]+=\\([a-z]+)%d+$")] then
      line = gsub(line, "%d+$", "...")
    end
    -- Also deal with showing boxes
    if match(line, "^> \\box%d+=$") or match(line, "^> \\box%d+=(void)$") then
      line = gsub(line, "%d+=", "...=")
    end
    -- Remove 'normal' direction information on boxes with (u)pTeX
    line = gsub(line, ",? yoko direction,?", "")
    line = gsub(line, ",? yoko%(math%) direction,?", "")
    -- Remove '\displace 0.0' lines in (u)pTeX
    if match(line,"^%.*\\displace 0%.0$") then
      return ""
     end
     -- Remove the \special line that in DVI mode keeps PDFs comparable
    if match(line, "^%.*\\special%{pdf: docinfo << /Creator") then
      return ""
    end
    -- Remove the \special line possibly present in DVI mode for paper size
    if match(line, "^%.*\\special%{papersize") then
      return ""
    end
    -- Remove ConTeXt stuff
    if match(line, "^backend         >") or
       match(line, "^close source    >") or
       match(line, "^mkiv lua stats  >") or
       match(line, "^pages           >") or
       match(line, "^system          >") or
       match(line, "^used file       >") or
       match(line, "^used option     >") or
       match(line, "^used structure  >") then
       return ""
    end
    -- A tidy-up to keep LuaTeX and other engines in sync
    line = gsub(line, utf8_char(127), "^^?")
    -- Unicode engines display chars in the upper half of the 8-bit range:
    -- tidy up to match pdfTeX if an ASCII engine is in use
    if next(asciiengines) then
      for i = 128, 255 do
        line = gsub(line, utf8_char(i), "^^" .. format("%02x", i))
      end
    end
    return line, lastline
  end
  local lastline = ""
  local newlog = ""
  local prestart = true
  local skipping = false
  -- Read the entire log file as a binary: deals with ^@/^[, etc.
  local file = assert(open(logfile, "rb"))
  local contents = gsub(file:read("*all") .. "\n", "\r\n", "\n")
  close(file)
  for line in gmatch(contents, "([^\n]*)\n") do
    if line == "START-TEST-LOG" then
      prestart = false
    elseif line == "END-TEST-LOG" or
      match(line, "^Here is how much of .?.?.?TeX\'s memory you used:") then
      break
    elseif line == "OMIT" then
      skipping = true
    elseif match(line, "^%)?TIMO$") then
      skipping = false
    elseif not prestart and not skipping then
      line, lastline = normalize(line, lastline)
      if not match(line, "^ *$") and not killcheck(line) then
        newlog = newlog .. line .. os_newline
      end
    end
  end
  local newfile = open(newfile, "w")
  output(newfile)
  write(newlog)
  if recordstatus then
    write('***************\n')
    for i = 1, checkruns do
      write('Compilation ' .. i .. ' of test file completed with exit status ' .. errlevels[i] .. '\n')
    end
  end
  close(newfile)
end

-- Additional normalization for LuaTeX
local function formatlualog(logfile, newfile, luatex)
  local function normalize(line, lastline, dropping)
    -- Find \discretionary or \whatsit lines:
    -- These may come back later
    if match(line, "^%.+\\discretionary$")                or
       match(line, "^%.+\\discretionary %(penalty 50%)$") or
       match(line, "^%.+\\discretionary50%|$")            or
       match(line, "^%.+\\discretionary50%| replacing $") or
       match(line, "^%.+\\whatsit$")                      then
      return "", line
    end
    -- For \mathon, we always need this line but the next
    -- may be affected
    if match(line, "^%.+\\mathon$") then
      return line, line
    end
    -- LuaTeX has a flexible output box
    line = gsub(line,"\\box\\outputbox", "\\box255")
    -- LuaTeX identifies spaceskip glue
    line = gsub(line,"%(\\spaceskip%) ", " ")
    -- Remove 'display' at end of display math boxes:
    -- LuaTeX omits this as it includes direction in all cases
    line = gsub(line, "(\\hbox%(.*), display$", "%1")
    -- Remove 'normal' direction information on boxes:
    -- any bidi/vertical stuff will still show
    line = gsub(line, ", direction TLT", "")
    -- Find glue setting and round out the last place
    local function round_digits(l, m)
      return gsub(
        l,
        m .. " (%-?)%d+%.%d+",
        m .. " %1"
          .. format(
            "%.3f",
            match(line, m .. " %-?(%d+%.%d+)") or 0
          )
      )
    end
    if match(line, "glue set %-?%d+%.%d+") then
      line = round_digits(line, "glue set")
    end
    if match(
        line, "glue %-?%d+%.%d+ plus %-?%d+%.%d+ minus %-?%d+%.%d+$"
      )
      then
      line = round_digits(line, "glue")
      line = round_digits(line, "plus")
      line = round_digits(line, "minus")
    end
    -- LuaTeX writes ^^M as a new line, which we lose
    line = gsub(line, "%^%^M", "")
    -- Remove U+ notation in the "Missing character" message
    line = gsub(
        line,
        "Missing character: There is no (%^%^..) %(U%+(....)%)",
        "Missing character: There is no %1"
      )
    -- The first time a new font is used, it shows up
    -- as being cached
    line = gsub(line, "(save cache:", "(load cache:")
    -- LuaTeX from v1.07 logs kerns differently ...
    -- This block only applies to the output of LuaTeX itself,
    -- hence needing a flag to skip the case of the reference log
    if luatex and
       tonumber(luatex_version) >= 107 and
       match(line, "^%.*\\kern") then
       -- Re-insert the space in explicit kerns
       if match(line, "kern%-?%d+%.%d+ *$") then
         line = gsub(line, "kern", "kern ")
       elseif match(line, "%(accent%)$") then
         line = gsub(line, "kern", "kern ")
         line = gsub(line, "%(accent%)$", "(for accent)")
       elseif match(line, "%(italic%)$") then
         line = gsub(line, "kern", "kern ")
         line = gsub(line, " %(italic%)$", "")
       else
         line = gsub(line, " %(font%)$", "")
       end
    end
    -- Changes in PDF specials
    line = gsub(line, "\\pdfliteral origin", "\\pdfliteral")
    -- A function to handle the box prefix part
    local function boxprefix(s)
      return gsub(match(s, "^(%.+)"), "%.", "%%.")
    end
    -- 'Recover' some discretionary data
    if match(lastline, "^%.+\\discretionary %(penalty 50%)$") and
       match(line, boxprefix(lastline) .. "%.= ") then
       line = gsub(line," %(font%)$","")
       return gsub(line, "%.= ", ""),""
    end
    -- Where the last line was a discretionary, looks for the
    -- info one level in about what it represents
    if match(lastline, "^%.+\\discretionary$")                or
       match(lastline, "^%.+\\discretionary %(penalty 50%)$") or
       match(lastline, "^%.+\\discretionary50%|$")            or
       match(lastline, "^%.+\\discretionary50%| replacing $") then
      local prefix = boxprefix(lastline)
      if match(line, prefix .. "%.") or
         match(line, prefix .. "%|") then
         if match(lastline, " replacing $") and
            not dropping then
           -- Modify the return line
           return gsub(line, "^%.", ""), lastline, true
         else
           return "", lastline, true
         end
      else
        if dropping then
          -- End of a \discretionary block
          return line, ""
        else
          -- Not quite a normal discretionary
          if match(lastline, "^%.+\\discretionary50%|$") then
            lastline =  gsub(lastline, "50%|$", "")
          end
          -- Remove some info that TeX90 lacks
          lastline = gsub(lastline, " %(penalty 50%)$", "")
          -- A normal (TeX90) discretionary:
          -- add with the line break reintroduced
          return lastline .. os_newline .. line, ""
        end
      end
    end
    -- Look for another form of \discretionary, replacing a "-"
    pattern = "^%.+\\discretionary replacing *$"
    if match(line, pattern) then
      return "", line
    else
      if match(lastline, pattern) then
        local prefix = boxprefix(lastline)
        if match(line, prefix .. "%.\\kern") then
          return gsub(line, "^%.", ""), lastline, true
        elseif dropping then
          return "", ""
        else
          return lastline .. os_newline .. line, ""
        end
      end
    end
    -- For \mathon, if the current line is an empty \hbox then
    -- drop it
    if match(lastline, "^%.+\\mathon$") then
      local prefix = boxprefix(lastline)
      if match(line, prefix .. "\\hbox%(0%.0%+0%.0%)x0%.0$") then
        return "", ""
      end
    end
    -- Various \local... things that other engines do not do:
    -- Only remove the no-op versions
    if match(line, "^%.+\\localpar$")                or
       match(line, "^%.+\\localinterlinepenalty=0$") or
       match(line, "^%.+\\localbrokenpenalty=0$")    or
       match(line, "^%.+\\localleftbox=null$")       or
       match(line, "^%.+\\localrightbox=null$")      then
       return "", ""
    end
    -- Older LuaTeX versions set the above up as a whatsit
    -- (at some stage this can therefore go)
    if match(lastline, "^%.+\\whatsit$") then
      local prefix = boxprefix(lastline)
      if match(line, prefix .. "%.") then
        return "", lastline, true
      else
        -- End of a \whatsit block
        return line, ""
      end
    end
    -- Wrap some cases that can be picked out
    -- In some places LuaTeX does use max_print_line, then we
    -- get into issues with different wrapping approaches
    if len(line) == maxprintline then
      return "", lastline .. line
    elseif len(lastline) == maxprintline then
      if match(line, "\\ETC%.%}$") then
        -- If the line wrapped at \ETC we might have lost a space
        return lastline
          .. ((match(line, "^\\ETC%.%}$") and " ") or "")
          .. line, ""
      elseif match(line, "^%}%}%}$") then
        return lastline .. line, ""
      else
        return lastline .. os_newline .. line, ""
      end
    -- Return all of the text for a wrapped (multi)line
    elseif len(lastline) > maxprintline then
      return lastline .. line, ""
    end
    -- Remove spaces at the start of lines: deals with the fact that LuaTeX
    -- uses a different number to the other engines
    return gsub(line, "^%s+", ""), ""
  end
  local newlog = ""
  local lastline = ""
  local dropping = false
  -- Read the entire log file as a binary: deals with ^@/^[, etc.
  local file = assert(open(logfile, "rb"))
  local contents = gsub(file:read("*all") .. "\n", "\r\n", "\n")
  close(file)
  for line in gmatch(contents, "([^\n]*)\n") do
    line, lastline, dropping = normalize(line, lastline, dropping)
    if not match(line, "^ *$") then
      newlog = newlog .. line .. os_newline
    end
  end
  local newfile = open(newfile, "w")
  output(newfile)
  write(newlog)
  close(newfile)
end

-- Run one test which may have multiple engine-dependent comparisons
-- Should create a difference file for each failed test
function runcheck(name, hide)
  local checkengines = checkengines
  if options["engine"] then
    checkengines = options["engine"]
  end
  local errorlevel = 0
  for _,i in ipairs(checkengines) do
    -- Allow for luatex == luajittex for .tlg purposes
    local engine = i
    if i == "luajittex" then
      engine = "luatex"
    end
    checkpdf = setup_check(name, engine)
    runtest(name, i, hide, lvtext, checkpdf)
    -- Generation of results depends on test type
    local errlevel
    if checkpdf then
      errlevel = compare_pdf(name, engine)
    else
      errlevel = compare_tlg(name, engine)
    end
    if errlevel ~= 0 and options["halt-on-error"] then
      showfaileddiff()
      if errlevel ~= 0 then
        return 1
      end
    end
    if errlevel > errorlevel then
      errorlevel = errlevel
    end
  end
  return errorlevel
end

function setup_check(name, engine)
  local testname = name .. "." .. engine
  local pdffile = locate(
    {testfiledir, unpackdir},
    {testname .. pdfext, name .. pdfext}
  )
  local tlgfile = locate(
    {testfiledir, unpackdir},
    {testname .. tlgext, name .. tlgext}
  )
  -- Attempt to generate missing reference file from expectation
  if not (pdffile or tlgfile) then
    if not locate({unpackdir, testfiledir}, {name .. lveext}) then
      print(
        "Error: failed to find " .. pdfext .. ", " .. tlgext .. " or "
          .. lveext .. " file for " .. name .. "!"
      )
      exit(1)
    end
    runtest(name, engine, true, lveext, true)
    pdffile = testdir .. "/" .. testname .. pdfext
    -- If a PDF is generated use it for comparisons
    if not fileexists(pdffile) then
      pdffile = nil
      ren(testdir, testname .. logext, testname .. tlgext)
    end
  else
    -- Install comparison files found
    for _,v in pairs({pdffile, tlgfile}) do
      if v then
        cp(
          match(v, ".*/(.*)"),
          match(v, "(.*)/.*"),
          testdir
        )
      end
    end
  end
  if pdffile then
    local pdffile = match(pdffile, ".*/(.*)")
    ren(
      testdir,
      pdffile,
      gsub(pdffile, pdfext .. "$", ".ref" .. pdfext)
    )
    return true
  else
    return false
  end
end

function compare_pdf(name, engine)
  local errorlevel
  local testname = name .. "." .. engine
  local cmpfile    = testdir .. "/" .. testname .. os_cmpext
  local pdffile    = testdir .. "/" .. testname .. pdfext
  local refpdffile = locate(
    {testdir}, {testname .. ".ref" .. pdfext, name .. ".ref" .. pdfext}
  )
  if not refpdffile then
    return
  end
  errorlevel = execute(
    os_cmpexe .. " " .. normalize_path(refpdffile)
      .. " " .. pdffile .. " > " .. cmpfile
  )
  if errorlevel == 0 then
    os.remove(cmpfile)
  end
  return errorlevel
end

function compare_tlg(name, engine)
  local errorlevel
  local testname = name .. "." .. engine
  local difffile = testdir .. "/" .. testname .. os_diffext
  local logfile  = testdir .. "/" .. testname .. logext
  local tlgfile  = locate({testdir}, {testname .. tlgext, name .. tlgext})
  if not tlgfile then
    return 1
  end
  -- Do additional log formatting if the engine is LuaTeX, there is no
  -- LuaTeX-specific .tlg file and the default engine is not LuaTeX
  if engine == "luatex"
    and not match(tlgfile, "%.luatex" .. "%" .. tlgext)
    and stdengine ~= "luatex"
    and stdengine ~= "luajittex"
    then
    local luatlgfile = testdir .. "/" .. name .. ".luatex" ..  tlgext
    formatlualog(tlgfile, luatlgfile, false)
    formatlualog(logfile, logfile, true)
    -- This allows code sharing below: we only need the .tlg name in one place
    tlgfile = luatlgfile
  end
  errorlevel = execute(os_diffexe .. " "
    .. normalize_path(tlgfile .. " " .. logfile .. " > " .. difffile))
  if errorlevel == 0 then
    os.remove(difffile)
  end
  return errorlevel
end

-- Run one of the test files: doesn't check the result so suitable for
-- both creating and verifying .tlg files
function runtest(name, engine, hide, ext, makepdf)
  local lvtfile = name .. (ext or lvtext)
  cp(lvtfile, fileexists(testfiledir .. "/" .. lvtfile)
    and testfiledir or unpackdir, testdir)
  local engine = engine or stdengine
  -- Set up the format file name if it's one ending "...tex"
  local realengine = engine
  local format
  if
    match(checkformat, "tex$") and
    not match(engine, checkformat) then
    format = " -fmt=" .. gsub(engine, "(.*)tex$", "%1") .. checkformat
  else
    format = ""
  end
  -- Special casing for e-LaTeX format
  if
    match(checkformat, "^latex$") and
    match(engine, "^etex$") then
    format = " -fmt=latex"
  end
  -- Special casing for (u)pTeX LaTeX formats
  if
    match(checkformat, "^latex$") and
    match(engine, "^u?ptex$") then
    realengine = "e" .. engine
  end
  -- Special casing for XeTeX engine
  local checkopts = checkopts
  if match(engine, "xetex") and not makepdf then
    checkopts = checkopts .. " -no-pdf"
  end
  -- Special casing for ConTeXt
  if match(checkformat, "^context$") then
    format = ""
    if engine == "luatex" or engine == "luajittex" then
      realengine = "context"
    elseif engine == "pdftex" then
      realengine = "texexec"
    elseif engine == "xetex" then
      realengine = "texexec --xetex"
    else
      print("Engine incompatible with format")
      exit(1)
    end
  end
  local logfile = testdir .. "/" .. name .. logext
  local newfile = testdir .. "/" .. name .. "." .. engine .. logext
  local asciiopt = ""
  for _,i in ipairs(asciiengines) do
    if realengine == i then
      asciiopt = "-translate-file ./ascii.tcx "
      break
    end
  end
  local errlevels = {}
  for i = 1, checkruns do
    errlevels[i] = run(
      testdir,
      -- No use of localdir here as the files get copied to testdir:
      -- avoids any paths in the logs
      os_setenv .. " TEXINPUTS=." .. (checksearch and os_pathsep or "")
        .. os_concat ..
      -- Avoid spurious output from (u)pTeX
      os_setenv .. " GUESS_INPUT_KANJI_ENCODING=0"
        .. os_concat ..
      (forcecheckepoch and setepoch() or "") ..
      -- Ensure lines are of a known length
      os_setenv .. " max_print_line=" .. maxprintline
        .. os_concat ..
      realengine .. format .. " -jobname=" .. name .. " "
        .. asciiopt .. " " .. checkopts .. " \"\\input " .. lvtfile .. "\" "
        .. (hide and (" > " .. os_null) or "")
        .. os_concat ..
      runtest_tasks(jobname(lvtfile))
    )
  end
  if makepdf and fileexists(testdir .. "/" .. name .. dviext) then
    dvitopdf(name, testdir, engine, hide)
  end
  formatlog(logfile, newfile, engine, errlevels)
  -- Store secondary files for this engine
  for _,filetype in pairs(auxfiles) do
    for _,file in pairs(filelist(testdir, filetype)) do
      if match(file,"^" .. name .. ".[^.]+$") then
        local ext = match(file, "%.[^.]+$")
        if ext ~= lvtext and
           ext ~= tlgext and
           ext ~= lveext and
           ext ~= logext then
           ren(testdir, file, gsub(file, "(%.[^.]+)$", "." .. engine .. "%1"))
        end
      end
    end
  end
end

-- A hook to allow additional tasks to run for the tests
runtest_tasks = runtest_tasks or function(name)
  return ""
end

-- Look for a test: could be in the testfiledir or the unpackdir
function testexists(test)
  return(locate({testfiledir, unpackdir}, {test .. lvtext}))
end

-- Standard versions of the main targets for building modules

function check(names)
  local errorlevel = 0
  if testfiledir ~= "" and direxists(testfiledir) then
    if not options["rerun"] then
      checkinit()
    end
    local hide = true
    if names and next(names) then
      hide = false
    end
    names = names or { }
    -- No names passed: find all test files
    if not next(names) then
      for _,i in pairs(filelist(testfiledir, "*" .. lvtext)) do
        insert(names, jobname(i))
      end
      for _,i in ipairs(filelist(unpackdir, "*" .. lvtext)) do
        if fileexists(testfiledir .. "/" .. i) then
          print("Duplicate test file: " .. i)
          return 1
        else
          insert(names, jobname(i))
        end
      end
      sort(names)
      -- Deal limiting range of names
      if options["first"] then
        local allnames = names
        local active = false
        local firstname = options["first"]
        names = { }
        for _,name in ipairs(allnames) do
          if name == firstname then
            active = true
          end
          if active then
            insert(names,name)
          end
        end
      end
      if options["last"] then
        local allnames = names
        local lastname = options["last"]
        names = { }
        for _,name in ipairs(allnames) do
          insert(names,name)
          if name == lastname then
            break
          end
        end
      end
    end
    -- https://stackoverflow.com/a/32167188
    local function shuffle(tbl)
      local len, random = #tbl, rnd
      for i = len, 2, -1 do
          local j = random(1, i)
          tbl[i], tbl[j] = tbl[j], tbl[i]
      end
      return tbl
    end
    if options["shuffle"] then
      names = shuffle(names)
    end
    -- Actually run the tests
    print("Running checks on")
    local i = 0
    for _,name in ipairs(names) do
      i = i + 1
      print("  " .. name .. " (" ..  i.. "/" .. #names ..")")
      local errlevel = runcheck(name, hide)
      -- Return value must be 1 not errlevel
      if errlevel ~= 0 then
        if options["halt-on-error"] then
          return 1
        else
          errorlevel = 1
          -- visually show that something has failed
          print("          --> failed\n")
        end
      end
    end
    if errorlevel ~= 0 then
      checkdiff()
    else
      print("\n  All checks passed\n")
    end
  end
  return errorlevel
end

-- A short auxiliary to print the list of differences for check
function checkdiff()
  print("\n  Check failed with difference files")
  for _,i in ipairs(filelist(testdir, "*" .. os_diffext)) do
    print("  - " .. testdir .. "/" .. i)
  end
  for _,i in ipairs(filelist(testdir, "*" .. os_cmpext)) do
    print("  - " .. testdir .. "/" .. i)
  end
  print("")
end

function showfaileddiff()
  print("\nCheck failed with difference file")
  for _,i in ipairs(filelist(testdir, "*" .. os_diffext)) do
    print("  - " .. testdir .. "/" .. i)
    print("")
    local f = open(testdir .. "/" .. i,"r")
    local content = f:read("*all")
    close(f)
    print("-----------------------------------------------------------------------------------")
    print(content)
    print("-----------------------------------------------------------------------------------")
  end
  for _,i in ipairs(filelist(testdir, "*" .. os_cmpext)) do
    print("  - " .. testdir .. "/" .. i)
  end
end

function save(names)
  checkinit()
  local engines = options["engine"] or {stdengine}
  for _,name in pairs(names) do
    local engine
    for _,engine in pairs(engines) do
      local tlgengine = ((engine == stdengine and "") or "." .. engine)
      local tlgfile  = name .. tlgengine .. tlgext
      local spdffile = name .. tlgengine .. pdfext
      local newfile  = name .. "." .. engine .. logext
      local pdffile  = name .. "." .. engine .. pdfext
      local refext = ((options["pdf"] and pdfext) or tlgext)
      if testexists(name) then
        print("Creating and copying " .. refext)
        runtest(name, engine, false, lvtext, options["pdf"])
        if options["pdf"] then
          ren(testdir, pdffile, spdffile)
          cp(spdffile, testdir, testfiledir)
        else
          ren(testdir, newfile, tlgfile)
          cp(tlgfile, testdir, testfiledir)
        end
        if fileexists(unpackdir .. "/" .. tlgfile) then
          print(
            "Saved " .. tlgext
              .. " file overrides unpacked version of the same name"
          )
        end
      elseif locate({unpackdir, testfiledir}, {name .. lveext}) then
        print(
          "Saved " .. tlgext .. " file overrides a "
            .. lveext .. " file of the same name"
        )
      else
        print(
          "Test input \"" .. testfiledir .. "/" .. name .. lvtext
            .. "\" not found"
        )
      end
    end
  end
end

