--[[

File l3build-check.lua Copyright (C) 2018-2023 The LaTeX Project

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
local str_format       = string.format
local gmatch           = string.gmatch
local gsub             = string.gsub
local match            = string.match

local insert           = table.insert
local sort             = table.sort

local utf8_char        = unicode.utf8.char

local exit             = os.exit
local execute          = os.execute
local remove           = os.remove

--
-- Auxiliary functions which are used by more than one main function
--

-- Set up the check system files: needed for checking one or more tests and
-- for saving the test files
function checkinit()
  if options["dirty"] then
    mkdir(testdir)
    mkdir(resultdir)
  else
    cleandir(testdir)
    cleandir(resultdir)
  end
  dep_install(checkdeps)
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
  return checkinit_hook()
end

function checkinit_hook() return 0 end

local function rewrite(source,result,processor,...)
  local file = assert(open(source,"rb"))
  local content = gsub(file:read("*all") .. "\n","\r\n","\n")
  close(file)
  local new_content = processor(content,...)
  local newfile = open(result,"w")
  output(newfile)
  write(new_content)
  close(newfile)
end

-- Convert the raw log file into one for comparison/storage: keeps only
-- the 'business' part from the tests and removes system-dependent stuff
local function normalize_log(content,engine,errlevels)
  local maxprintline = maxprintline
  if (match(engine,"^lua") or match(engine,"^harf")) and luatex_version < 113 then
    maxprintline = maxprintline + 1 -- Deal with an out-by-one error
  end
  local function killcheck(line)
      -- Skip \openin/\openout lines in web2c 7.x
      -- As Lua doesn't allow "(in|out)", a slightly complex approach:
      -- do a substitution to check the line is exactly what is required!
    if match(gsub(line, "^\\openin", "\\openout"), "^\\openout%d%d? = ") then
      return true
    end
    return false
  end
    -- Substitutions to remove some non-useful changes
  local function normalize(line,lastline,drop_fd)
    if drop_fd then
      if match(line," *%)") then
        return "",""
      else
        return "","",true
      end
    end
    -- Zap line numbers from \show, \showbox, \box_show and the like:
    -- do this before wrapping lines
    line = gsub(line, "^l%.%d+ ", "l. ...")
    -- Also from Lua stack traces
    line = gsub(line, "lua:%d+:", "lua:...:")
    -- Allow for wrapped lines: preserve the content and wrap
    -- Skip lines that have an explicit marker for truncation
    if len(line) == maxprintline  and
       not match(line, "%.%.%.$") then
      return "", (lastline or "") .. line
    end
    line = (lastline or "") .. line
    lastline = ""
    -- Zap ./ at begin of filename
    line = gsub(line, "%(%.%/", "(")
    -- Zap paths
    -- The pattern excludes < and > as the image part can have
    -- several entries on one line
    local pattern = "%w?:?/[^ %<%>]*/([^/%(%)]*%.%w*)"
    -- Files loaded from TeX: all start ( -- )
    line = gsub(line, "%(" .. pattern, "(../%1")
    -- Images
    line = gsub(line, "<" .. pattern .. ">", "<../%1>")
    -- luaotfload files start with keywords
    line = gsub(line, "from " .. pattern .. "$", "from ../%1")
    line = gsub(line, ": " .. pattern .. "%)", ": ../%1)")
    -- Deal with XeTeX specials
    if match(line, "^%.+\\XeTeX.?.?.?file") then
      line = gsub(line, pattern, "../%1")
    end
    -- pdfTeX .enc files
    if match(line, "%.enc%}") then
      line = gsub(line,"%{" .. pattern .. "%}","")
    end
    -- Deal with dates
    if match(line, "[^<]%d%d%d%d[/%-]%d%d[/%-]%d%d") then
        line = gsub(line,"%d%d%d%d[/%-]%d%d[/%-]%d%d","....-..-..")
        line = gsub(line,"v%d+%.?%d?%d?%w?","v...")
    end
    -- Deal with leading spaces for file and page number lines
    line = gsub(line,"^ *%[(%d)","[%1")
    line = gsub(line,"^ *%(","(")
    -- Zap .fd lines: drop the first part, and skip to the end
    if match(line, "^ *%([%.%/%w]+%.fd[^%)]*$") then
      return "","",true
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
    if not match(stdengine,"^e?u?ptex$") then
      -- Remove 'normal' direction information on boxes with (u)pTeX
      line = gsub(line, ",? yoko direction,?", "")
      line = gsub(line, ",? yoko%(math%) direction,?", "")
      -- Remove '\displace 0.0' lines in (u)pTeX
      if match(line,"^%.*\\displace 0%.0$") then
        return ""
      end
    end
    -- Deal with Lua function calls
    if match(line, "^Lua function") then
      line = gsub(line,"= %d+$","= ...")
    end
    -- Remove the \special line that in DVI mode keeps PDFs comparable
    if match(line, "^%.*\\special%{pdf: docinfo << /Creator") or
      match(line, "^%.*\\special%{ps: /setdistillerparams") or
      match(line, "^%.*\\special%{! <</........UUID") then
      return ""
    end
    -- Remove \special lines for DVI .pro files
    if match(line, "^%.*\\special%{header=") then
      return ""
    end
    if match(line, "^%.*\\special%{dvipdfmx:config") then
      return ""
    end
    -- Remove the \special line possibly present in DVI mode for paper size
    if match(line, "^%.*\\special%{papersize") then
      return ""
    end
    -- Remove bidi version in \special lines line
    if match(line, "BIDI.Fullbanner") then
      line = gsub(line,"Version %d*%.%d*", "Version ...")
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
    -- The first time a new font is used by LuaTeX, it shows up
    -- as being cached: make it appear loaded every time
    line = gsub(line, "save cache:", "load cache:")
    -- A tidy-up to keep LuaTeX and other engines in sync
    line = gsub(line, utf8_char(127), "^^?")
    -- Remove lua data reference ids
    line = gsub(line, "<lua data reference [0-9]+>",
                      "<lua data reference ...>")
    -- Unicode engines display chars in the upper half of the 8-bit range:
    -- tidy up to match pdfTeX if an ASCII engine is in use
    if next(asciiengines) then
      for i = 128, 255 do
        line = gsub(line, utf8_char(i), "^^" .. str_format("%02x", i))
      end
    end
    return line, lastline
  end
  local lastline = ""
  local drop_fd = false
  local new_content = ""
  local prestart = true
  local skipping = false
  for line in gmatch(content, "([^\n]*)\n") do
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
      line, lastline, drop_fd = normalize(line, lastline,drop_fd)
      if not match(line, "^ *$") and not killcheck(line) then
        new_content = new_content .. line .. os_newline
      end
    end
  end
  if recordstatus then
    new_content = new_content .. '***************' .. os_newline
    for i = 1, checkruns do
      if (errlevels[i]==nil) then
        new_content = new_content ..
          'Compilation ' .. i .. ' of test file skipped ' .. os_newline
      else
        new_content = new_content ..
          'Compilation ' .. i .. ' of test file completed with exit status ' ..
          errlevels[i] .. os_newline
      end
    end
  end
  return new_content
end

-- Additional normalization for LuaTeX
local function normalize_lua_log(content,luatex)
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
          .. str_format(
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
    local pattern = "^%.+\\discretionary replacing *$"
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
  local new_content = ""
  local lastline = ""
  local dropping = false
  for line in gmatch(content, "([^\n]*)\n") do
    line, lastline, dropping = normalize(line, lastline, dropping)
    if not match(line, "^ *$") then
      new_content = new_content .. line .. os_newline
    end
  end
  return new_content
end

local function normalize_pdf(content)
  local new_content = ""
  local stream_content = ""
  local binary = false
  local stream = false
  for line in gmatch(content,"([^\n]*)\n") do
    if stream then
      if match(line,"endstream") then
        stream = false
        if binary then
          new_content = new_content .. "[BINARY STREAM]" .. os_newline
        else
          new_content = new_content .. stream_content .. line .. os_newline
        end
        binary = false
      else
        for i = 0, 31 do
          if match(line,char(i)) then
            binary = true
            break
          end
        end
        if not binary and not match(line, "^ *$") then
          stream_content = stream_content .. line .. os_newline
        end
      end
    elseif match(line,"^stream$") then
      binary = false
      stream = true
      stream_content = "stream" .. os_newline
    elseif not match(line, "^ *$") and
      not match(line,"^%%%%Invocation") and
      not match(line,"^%%%%%+") then
      line = gsub(line,"%/ID( ?)%[<[^>]+><[^>]+>]","/ID%1[<ID-STRING><ID-STRING>]")
      line = gsub(line,"%/ID( ?)%[(%b())%2%]","/ID%1[<ID-STRING><ID-STRING>]")
      line = gsub(line,"Ghost[sS]cript %d+%.%d+%.?%d*","Ghostscript ...")
      new_content = new_content .. line .. os_newline
    end
  end
  return new_content
end

function rewrite_log(source, result, engine, errlevels)
  return rewrite(source, result, normalize_log, engine, errlevels)
end

function rewrite_pdf(source, result, engine, errlevels)
  return rewrite(source, result, normalize_pdf, engine, errlevels)
end

-- Run one test which may have multiple engine-dependent comparisons
-- Should create a difference file for each failed test
function runcheck(name, hide)
  local test_filename, kind = testexists(name)
  if not test_filename then
    print("Failed to find input for test " .. name)
    return 1
  end
  local checkengines = checkengines
  if options["engine"] then
    checkengines = options["engine"]
  end
  local failedengines = {}
  -- Used for both .lvt and .pvt tests
  local test_type = test_types[kind]
  local function check_and_diff(engine)
    runtest(name, engine, hide, test_type.test, test_type, not forcecheckruns)
    local errorlevel = base_compare(test_type,name,engine)
    if errorlevel == 0 then
      return errorlevel
    end
    failedengines[#failedengines + 1] = engine
    if options["show-log-on-error"] then
      showfailedlog(name)
    end
    if options["halt-on-error"] then
      showfaileddiff()
    end
    return errorlevel
  end
  local errorlevel = 0
  for _,engine in pairs(checkengines) do
    setup_check(name,engine)
    local errlevel = check_and_diff(engine)
    if errlevel ~= 0 and options["halt-on-error"] then
      return 1, failedengines
    end
    if errlevel > errorlevel then
      errorlevel = errlevel
    end
  end
  for i=1, #failedengines do
     if failedengines[i] == stdengine then
        failedengines = {stdengine}
        break
     end
  end
  -- Return everything
  return errorlevel, failedengines
end

function setup_check(name, engine)
  local testname = name .. "." .. engine
  local found
  for _, kind in ipairs(test_order) do
    local reference_ext = test_types[kind].reference
    local reference_file = locate(
      {testfiledir, unpackdir},
      {testname .. reference_ext, name .. reference_ext}
    )
    if reference_file then
      found = true
      -- Install comparison file found
      cp(
        match(reference_file, ".*/(.*)"),
        match(reference_file, "(.*)/.*"),
        testdir
      )
    end
  end
  if found then
     return
  end
  -- Attempt to generate missing reference file from expectation
  for _, kind in ipairs(test_order) do
    local test_type = test_types[kind]
    local exp_ext = test_type.expectation
    local expectation_file = exp_ext and locate(
      {testfiledir, unpackdir},
      {name .. exp_ext}
    )
    if expectation_file then
      found = true
      runtest(name, engine, true, exp_ext, test_type)
      ren(testdir, testname .. test_type.generated, testname .. test_type.reference)
    end
  end
  if found then
     return
  end
  print(
    "Error: failed to find any reference or expectation file for "
      .. name .. "!"
  )
  exit(1)
end

function base_compare(test_type,name,engine,cleanup)
  local testname = name .. "." .. engine
  local difffile = testdir .. "/" .. testname.. os_diffext
  local genfile  = testdir .. "/" .. testname .. test_type.generated
  local reffile  = locate({testdir}, {testname .. test_type.reference, name .. test_type.reference})
  if not reffile then
    return 1
  end
  local compare = test_type.compare
  if compare then
    return compare(difffile, reffile, genfile, cleanup, name, engine)
  end
  local errorlevel = execute(os_diffexe .. " "
    .. normalize_path(reffile .. " " .. genfile .. " > " .. difffile))
  if errorlevel == 0 or cleanup then
    remove(difffile)
  end
  return errorlevel
end

function compare_tlg(difffile, tlgfile, logfile, cleanup, name, engine)
  local errorlevel
  local testname = name .. "." .. engine
  -- Do additional log formatting if the engine is LuaTeX, there is no
  -- engine-specific .tlg file and the default engine is not LuaTeX
  local has_engine_specific_tlg =
      match(tlgfile, "%." .. engine .. "%" .. tlgext)
      and locate({ testfiledir, unpackdir }, { tlgfile })
  if (match(engine,"^lua") or match(engine,"^harf"))
    and not has_engine_specific_tlg
    and not match(stdengine,"^lua")
    then
    local lualogfile = logfile
    if cleanup then
      lualogfile = testdir .. "/" .. testname .. ".tmp" .. logext
    end
    local luatlgfile = testdir .. "/" .. testname .. tlgext
    rewrite(tlgfile,luatlgfile,normalize_lua_log)
    rewrite(logfile,lualogfile,normalize_lua_log,true)
    errorlevel = execute(os_diffexe .. " "
      .. normalize_path(luatlgfile .. " " .. lualogfile .. " > " .. difffile))
    if cleanup then
      remove(lualogfile)
      remove(luatlgfile)
    end
  else
    errorlevel = execute(os_diffexe .. " "
      .. normalize_path(tlgfile .. " " .. logfile .. " > " .. difffile))
  end
  if errorlevel == 0 or cleanup then
    remove(difffile)
  end
  return errorlevel
end

-- Run one of the test files: doesn't check the result so suitable for
-- both creating and verifying
function runtest(name, engine, hide, ext, test_type, breakout)
  local lvtfile = name .. (ext or lvtext)
  cp(lvtfile, fileexists(testfiledir .. "/" .. lvtfile)
    and testfiledir or unpackdir, testdir)
  local checkopts = checkopts
  local tokens = ""
  engine = engine or stdengine
  local binary = engine
  local format = gsub(engine,"tex$",checkformat)
  -- Special binary/format combos
  local special_check = specialformats[checkformat]
  if special_check and next(special_check) then
    local engine_info = special_check[engine]
    if engine_info then
      binary    = engine_info.binary  or binary
      format    = engine_info.format  or format
      checkopts = engine_info.options or checkopts
      tokens    = engine_info.tokens and (' "' .. engine_info.tokens .. '" ')
                    or tokens
    end
  end
  -- Finalise format string
  if format ~= "" then
    format = " --fmt=" .. format
  end
  -- Special casing for XeTeX engine
  if match(engine, "xetex") and test_type.generated ~= pdfext then
    checkopts = checkopts .. " -no-pdf"
  end
  -- Special casing for ConTeXt
  local function setup(file)
    return " -jobname=" .. name .. tokens .. ' "\\input ' .. file .. '" '
  end
  if match(checkformat,"^context$") then
    function setup(file) return tokens .. ' "' .. file .. '" '  end
  end
  if match(binary,"make4ht") then
    function setup(file) return tokens .. ' "' .. file .. '" '  end
    format = ""
    checkopts = ""
  end
  local basename = testdir .. "/" .. name
  local gen_file = basename .. test_type.generated
  local new_file = basename .. "." .. engine .. test_type.generated
  local asciiopt = ""
  for _,i in ipairs(asciiengines) do
    if binary == i then
      asciiopt = "-translate-file ./ascii.tcx "
      break
    end
  end
  -- Clean out any dynamic files
  for _,filetype in pairs(dynamicfiles) do
    rm(testdir,filetype)
  end
  -- Ensure there is no stray .log file
  rmfile(testdir,name .. logext)
  local errlevels = {}
  for i = 1, checkruns do
    errlevels[i] = runcmd(
      -- No use of localdir here as the files get copied to testdir:
      -- avoids any paths in the logs
      os_setenv .. " TEXINPUTS=." .. localtexmf()
        .. (checksearch and os_pathsep or "")
        .. os_concat ..
      os_setenv .. " LUAINPUTS=." .. localtexmf()
        .. (checksearch and os_pathsep or "")
        .. os_concat ..
      -- ensure epoch settings
      set_epoch_cmd(epoch, forcecheckepoch) ..
      -- Ensure lines are of a known length
      os_setenv .. " max_print_line=" .. maxprintline
        .. os_concat ..
      binary .. format
        .. " " .. asciiopt .. " " .. checkopts
        .. setup(lvtfile)
        .. (hide and (" > " .. os_null) or "")
        .. os_concat ..
      runtest_tasks(jobname(lvtfile),i),
      testdir
    )
    -- Break the loop if the result is stable
    if breakout and i < checkruns then
      if test_type.generated == pdfext then
        if fileexists(testdir .. "/" .. name .. dviext) then
          dvitopdf(name, testdir, engine, hide)
        end
      end
      test_type.rewrite(gen_file,new_file,engine,errlevels)
      if base_compare(test_type,name,engine,true) == 0 then
        break
      end
    end
  end
  if test_type.generated == pdfext then
    if fileexists(testdir .. "/" .. name .. dviext) then
      dvitopdf(name, testdir, engine, hide)
    end
    cp(name .. pdfext,testdir,resultdir)
    ren(resultdir,name .. pdfext,name .. "." .. engine .. pdfext)
  end
  test_type.rewrite(gen_file,new_file,engine,errlevels)
  -- Store secondary files for this engine
  for _,filetype in pairs(auxfiles) do
    for _,file in ipairs(filelist(testdir, filetype)) do
      if match(file,"^" .. name .. "%.[^.]+$") then
        local newname = gsub(file,"(%.[^.]+)$","." .. engine .. "%1")
        if fileexists(testdir .. "/" .. newname) then
          rmfile(testdir,newname)
        end
        ren(testdir,file,newname)
      end
    end
  end
  return 0
end

-- A hook to allow additional tasks to run for the tests
function runtest_tasks(name,run)
  return ""
end

-- Look for a test: could be in the testfiledir or the unpackdir
function testexists(test)
  local filenames = {}
  for i, kind in ipairs(test_order) do
    filenames[i] = test .. test_types[kind].test
  end
  local found = locate({testfiledir, unpackdir}, filenames)
  if found then
    for i, kind in ipairs(test_order) do
      local filename = filenames[i]
      if found:sub(-#filename) == filename then
        return found, kind
      end
    end
  end
end

-- A short auxiliary to print the list of differences for check
local function showsavecommands(failurelist)
  local savecmds = {}
  local checkcmd = "l3build check --show-saves"
  local prefix = "l3build save"
  if options.config and options.config[1] ~= 'build' then
    local config = " -c " .. options.config[1]
    prefix = prefix .. config
    checkcmd = checkcmd .. config
  end
  for name, engines in pairs(failurelist) do
    for i = 1, #engines do
      local engine = engines[i]
      local cmd = savecmds[engine]
      if not cmd then
        if engine == stdengine then
          cmd = prefix
        else
          cmd = prefix .. " -e " .. engine
        end
      end
      savecmds[engine] = cmd .. " " .. name
      if engine == stdengine then
        checkcmd = checkcmd .. " " .. name
      end
    end
  end
  print("  To regenerate the test files, run\n")
  local f = open(testdir .. "/.savecommands", "w")
  for _, cmds in pairs(savecmds) do
    print("    " .. cmds)
    f:write(cmds, "\n")
  end
  f:write"\n"
  if savecmds[stdengine] then
     print("\n  Afterwards test for engine specific changes using\n")
     print("    " .. checkcmd)
     f:write(checkcmd)
  end
  f:close()
  print("")
end

function check(names)
  local errorlevel = 0
  if testfiledir ~= "" and direxists(testfiledir) then
    if not options["rerun"] then
      errorlevel = checkinit()
      if errorlevel ~= 0 then
        return errorlevel
      end
    end
    local hide = true
    if names and next(names) then
      hide = false
    end
    names = names or { }
    -- No names passed: find all test files
    if not next(names) then
      for _, kind in ipairs(test_order) do
        local ext = test_types[kind].test
        local excludepatterns = { }
        local num_exclude = 0
        for _,glob in pairs(excludetests) do
          num_exclude = num_exclude+1
          excludepatterns[num_exclude] = glob_to_pattern(glob .. ext)
        end
        for _,glob in pairs(includetests) do
          for _,name in ipairs(filelist(testfiledir, glob .. ext)) do
            local exclude
            for i=1, num_exclude do
              if match(name, excludepatterns[i]) then
                exclude = true
                break
              end
            end
            if not exclude then
              insert(names,jobname(name))
            end
          end
          for _,name in ipairs(filelist(unpackdir, glob .. ext)) do
            local exclude
            for i=1, num_exclude do
              if not match(name, excludepatterns[i]) then
                exclude = true
                break
              end
            end
            if not exclude then
              if fileexists(testfiledir .. "/" .. name) then
                return 1
              end
              insert(names,jobname(name))
            end
          end
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
    if options["shuffle"] then
      -- https://stackoverflow.com/a/32167188
      for i = #names, 2, -1 do
        local j = rnd(1, i)
        names[i], names[j] = names[j], names[i]
      end
    end
    -- Actually run the tests
    print("Running checks on")
    local failurelist = {}
    for i, name in ipairs(names) do
      print("  " .. name .. " (" ..  i .. "/" .. #names ..")")
      local errlevel, failedengines = runcheck(name, hide)
      -- Return value must be 1 not errlevel
      if errlevel ~= 0 then
        failurelist[name] = failedengines
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
      if options["show-saves"] then
        showsavecommands(failurelist)
      end
    else
      print("\n  All checks passed\n")
    end
  end
  return errorlevel
end

-- A short auxiliary to print the list of differences for check
function checkdiff()
  print("\n  Check failed with difference files")
  for _,i in ipairs(ordered_filelist(testdir, "*" .. os_diffext)) do
    print("  - " .. testdir .. "/" .. i)
  end
  print("")
end

function showfailedlog(name)
  print("\nCheck failed with log file")
  for _,i in ipairs(ordered_filelist(testdir, name..".log")) do
    print("  - " .. testdir .. "/" .. i)
    print("")
    local f = open(testdir .. "/" .. i,"r")
    local content = f:read("*all")
    close(f)
    print("-----------------------------------------------------------------------------------")
    print(content)
    print("-----------------------------------------------------------------------------------")
  end
end

function showfaileddiff()
  print("\nCheck failed with difference file")
  for _,i in ipairs(ordered_filelist(testdir, "*" .. os_diffext)) do
    print("  - " .. testdir .. "/" .. i)
    print("")
    local f = open(testdir .. "/" .. i,"r")
    local content = f:read("*all")
    close(f)
    print("-----------------------------------------------------------------------------------")
    print(content)
    print("-----------------------------------------------------------------------------------")
  end
end

function save(names)
  do
    local errorlevel = checkinit()
    if errorlevel ~= 0 then
      return errorlevel
    end
  end
  local engines = options["engine"] or {stdengine}
  if names == nil then
    print("Arguments are required for the save command")
    return 1
  end
  for _,name in pairs(names) do
    local test_filename, kind = testexists(name)
    if not test_filename then
      print('Test "' .. name .. '" not found')
      return 1
    end
    local test_type = test_types[kind]
    if test_type.expectation and locate({unpackdir, testfiledir}, {name .. test_type.expectation}) then
      print("Saved " .. test_type.test .. " file would override a "
        .. test_type.expectation .. " file of the same name")
      return 1
    end
    for _,engine in pairs(engines) do
      local testengine = engine == stdengine and "" or ("." .. engine)
      local out_file = name .. testengine .. test_type.reference
      local gen_file = name .. "." .. engine .. test_type.generated
      print("Creating and copying " .. out_file)
      runtest(name, engine, false, test_type.test, test_type)
      ren(testdir, gen_file, out_file)
      cp(out_file, testdir, testfiledir)
      if fileexists(unpackdir .. "/" .. test_type.reference) then
        print("Saved " .. test_type.reference
          .. " file overrides unpacked version of the same name")
        return 1
      end
    end
  end
  return 0
end
