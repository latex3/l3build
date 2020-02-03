--[[

File l3build-check.lua Copyright (C) 2018,2019 The LaTeX3 Project

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
local remove           = os.remove

--
-- Auxiliary functions which are used by more than one main function
--

-- Set up the check system files: needed for checking one or more tests and
-- for saving the test files
function checkinit()
  if not options["dirty"] then
    cleandir(testdir)
  end
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
  return checkinit_hook()
end

checkinit_hook = checkinit_hook or function() return 0 end

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
  if match(engine,"^lua") or match(engine,"^harf") then
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
    -- Zap paths
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
     -- Remove the \special line that in DVI mode keeps PDFs comparable
    if match(line, "^%.*\\special%{pdf: docinfo << /Creator") then
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
        line = gsub(line, utf8_char(i), "^^" .. format("%02x", i))
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
      new_content = new_content ..
        'Compilation ' .. i .. ' of test file completed with exit status ' ..
        errlevels[i] .. os_newline
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
    elseif not match(line, "^ *$") then
      new_content = new_content .. line .. os_newline
    end
  end
  return new_content
end

-- Run one test which may have multiple engine-dependent comparisons
-- Should create a difference file for each failed test
function runcheck(name, hide)
  if not testexists(name) then
    print("Failed to find input for test " .. name)
    return 1
  end
  local checkengines = checkengines
  if options["engine"] then
    checkengines = options["engine"]
  end
  -- Used for both .lvt and .pvt tests
  local function check_and_diff(ext,engine,comp,pdftest)
    runtest(name,engine,hide,ext,pdftest,true)
    local errorlevel = comp(name,engine)
    if errorlevel == 0 then
      return errorlevel
    end
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
    local errlevel = 0
    if fileexists(testfiledir .. "/" .. name .. pvtext) then
      errlevel = check_and_diff(pvtext,engine,compare_pdf,true)
    else
      errlevel = check_and_diff(lvtext,engine,compare_tlg)
    end
    if errlevel ~= 0 and options["halt-on-error"] then
      return 1
    end
    if errlevel > errorlevel then
      errorlevel = errlevel
    end
  end
  -- Return everything
  return errorlevel
end

function setup_check(name, engine)
  local testname = name .. "." .. engine
  local tlgfile = locate(
    {testfiledir, unpackdir},
    {testname .. tlgext, name .. tlgext}
  )
  local tpffile = locate(
    {testfiledir, unpackdir},
    {testname .. tpfext, name .. tpfext}
  )
  -- Attempt to generate missing reference file from expectation
  if not (tlgfile or tpffile) then
    if not locate({unpackdir, testfiledir}, {name .. lveext}) then
      print(
        "Error: failed to find " .. tlgext .. ", " .. tpfext .. " or "
          .. lveext .. " file for " .. name .. "!"
      )
      exit(1)
    end
    runtest(name, engine, true, lveext)
    ren(testdir, testname .. logext, testname .. tlgext)
  else
    -- Install comparison files found
    for _,v in pairs({tlgfile, tpffile}) do
      if v then
        cp(
          match(v, ".*/(.*)"),
          match(v, "(.*)/.*"),
          testdir
        )
      end
    end
  end
end

function compare_pdf(name,engine,cleanup)
  local testname = name .. "." .. engine
  local difffile = testdir .. "/" .. testname .. pdfext .. os_diffext
  local pdffile  = testdir .. "/" .. testname .. pdfext
  local tpffile  = locate({testdir}, {testname .. tpfext, name .. tpfext})
  if not tpffile then
    return 1
  end
  local errorlevel = execute(os_diffexe .. " "
    .. normalize_path(tpffile .. " " .. pdffile .. " > " .. difffile))
  if errorlevel == 0 or cleanup then
    remove(difffile)
  end
  return errorlevel
end

function compare_tlg(name,engine,cleanup)
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
  if (match(engine,"^lua") or match(engine,"^harf"))
    and not match(tlgfile, "%.luatex" .. "%" .. tlgext)
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
function runtest(name, engine, hide, ext, pdfmode, breakout)
  local lvtfile = name .. (ext or lvtext)
  cp(lvtfile, fileexists(testfiledir .. "/" .. lvtfile)
    and testfiledir or unpackdir, testdir)
  local checkopts = checkopts
  local engine = engine or stdengine
  local binary = engine
  local format = gsub(engine,"tex$",checkformat)
  -- Special binary/format combos
  if specialformats[checkformat] and next(specialformats[checkformat]) then
    local t = specialformats[checkformat]
    if t[engine] and next(t[engine]) then
      local t = t[engine]
      binary    = t.binary  or binary
      checkopts = t.options or checkopts
      format    = t.format  or format
    end
  end
  -- Finalise format string
  if format ~= "" then
    format = " --fmt=" .. format
  end
  -- Special casing for XeTeX engine
  if match(engine, "xetex") and not pdfmode then
    checkopts = checkopts .. " -no-pdf"
  end
  -- Special casing for ConTeXt
  local function setup(file)
    return " -jobname=" .. name .. " " .. ' "\\input ' .. file .. '" '
  end
  if match(checkformat,"^context$") then
    function setup(file) return ' "' .. file .. '" '  end
  end
  local basename = testdir .. "/" .. name
  local logfile = basename .. logext
  local newfile = basename .. "." .. engine .. logext
  local pdffile = basename .. pdfext
  local npffile = basename .. "." .. engine .. pdfext
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
  rm(testdir,name .. logext)
  local errlevels = {}
  local localtexmf = ""
  if texmfdir and texmfdir ~= "" and direxists(texmfdir) then
    localtexmf = os_pathsep .. abspath(texmfdir) .. "//"
  end
  for i = 1, checkruns do
    errlevels[i] = run(
      testdir,
      -- No use of localdir here as the files get copied to testdir:
      -- avoids any paths in the logs
      os_setenv .. " TEXINPUTS=." .. localtexmf
        .. (checksearch and os_pathsep or "")
        .. os_concat ..
      os_setenv .. " LUAINPUTS=." .. localtexmf
        .. (checksearch and os_pathsep or "")
        .. os_concat ..
      -- Avoid spurious output from (u)pTeX
      os_setenv .. " GUESS_INPUT_KANJI_ENCODING=0"
        .. os_concat ..
      -- Allow for local texmf files
      os_setenv .. " TEXMFCNF=." .. os_pathsep
        .. os_concat ..
      (forcecheckepoch and setepoch() or "") ..
      -- Ensure lines are of a known length
      os_setenv .. " max_print_line=" .. maxprintline
        .. os_concat ..
      binary .. format
        .. " " .. asciiopt .. " " .. checkopts
        .. setup(lvtfile)
        .. (hide and (" > " .. os_null) or "")
        .. os_concat ..
      runtest_tasks(jobname(lvtfile),i)
    )
    -- Break the loop if the result is stable
    if breakout and i < checkruns then
      if pdfmode then
        rewrite(pdffile,npffile,normalize_pdf)
        if compare_pdf(name,engine,true) == 0 then
          break
        end
      else
        rewrite(logfile,newfile,normalize_log,engine,errlevels)
        if compare_tlg(name,engine,true) == 0 then
          break
        end
      end
    end
  end
  if pdfmode and fileexists(testdir .. "/" .. name .. dviext) then
    dvitopdf(name, testdir, engine, hide)
  end
  if pdfmode then
    rewrite(pdffile,npffile,normalize_pdf)
  else
    rewrite(logfile,newfile,normalize_log,engine,errlevels)
  end
  -- Store secondary files for this engine
  for _,filetype in pairs(auxfiles) do
    for _,file in pairs(filelist(testdir, filetype)) do
      if match(file,"^" .. name .. ".[^.]+$") then
        local ext = match(file, "%.[^.]+$")
        if ext ~= lvtext and
           ext ~= tlgext and
           ext ~= lveext and
           ext ~= logext then
           local newname = gsub(file,"(%.[^.]+)$","." .. engine .. "%1")
           if fileexists(testdir,newname) then
             rm(testdir,newname)
           end
           ren(testdir,file,newname)
        end
      end
    end
  end
  return 0
end

-- A hook to allow additional tasks to run for the tests
runtest_tasks = runtest_tasks or function(name,run)
  return ""
end

-- Look for a test: could be in the testfiledir or the unpackdir
function testexists(test)
  return(locate({testfiledir, unpackdir},
    {test .. lvtext, test .. pvtext}))
end

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
      local excludenames = { }
      for _,glob in pairs(excludetests) do
        for _,name in pairs(filelist(testfiledir, glob .. lvtext)) do
          excludenames[jobname(name)] = true
        end
        for _,name in pairs(filelist(unpackdir, glob .. lvtext)) do
          excludenames[jobname(name)] = true
        end
        for _,name in pairs(filelist(testfiledir, glob .. pvtext)) do
          excludenames[jobname(name)] = true
        end
      end
      local function addname(name)
        if not excludenames[jobname(name)] then
          insert(names,jobname(name))
        end
      end
      for _,glob in pairs(includetests) do
        for _,name in pairs(filelist(testfiledir, glob .. lvtext)) do
          addname(name)
        end
        for _,name in pairs(filelist(testfiledir, glob .. pvtext)) do
          addname(name)
        end
        for _,name in pairs(filelist(unpackdir, glob .. lvtext)) do
          if fileexists(testfiledir .. "/" .. name) then
            print("Duplicate test file: " .. i)
            return 1
          end
          addname(name)
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
  print("")
end

function showfailedlog(name)
  print("\nCheck failed with log file")
  for _,i in ipairs(filelist(testdir, name..".log")) do
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
end

function save(names)
  checkinit()
  local engines = options["engine"] or {stdengine}
  if names == nil then
    print("Arguments are required for the save command")
    return 1
  end
  for _,name in pairs(names) do
    if testexists(name) then
      for _,engine in pairs(engines) do
        local testengine = ((engine == stdengine and "") or "." .. engine)
        local function save_test(test_ext,gen_ext,out_ext,pdfmode)
          local out_file = name .. testengine .. out_ext
          local gen_file = name .. "." .. engine .. gen_ext
          print("Creating and copying " .. out_file)
          runtest(name,engine,false,test_ext,pdfmode)
          ren(testdir,gen_file,out_file)
          cp(out_file,testdir,testfiledir)
          if fileexists(unpackdir .. "/" .. out_file) then
            print("Saved " .. out_ext
              .. " file overrides unpacked version of the same name")
            return 1
          end
          return 0
        end
        local errorlevel
        if fileexists(testfiledir .. "/" .. name .. lvtext) then
          errorlevel = save_test(lvtext,logext,tlgext)
        else
          errorlevel = save_test(pvtext,pdfext,tpfext,true)
        end
        if errorlevel ~=0 then return errorlevel end
      end
    elseif locate({unpackdir, testfiledir}, {name .. lveext}) then
      print("Saved " .. tlgext .. " file overrides a "
        .. lveext .. " file of the same name")
      return 1
    else
      print('Test "' .. name .. '" not found')
      return 1
    end
  end
  return 0
end
