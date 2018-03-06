#!/usr/bin/env texlua

-- Build script for LaTeX3 "l3build" files

-- Identify the bundle and module
module = "l3build"
bundle = ""

-- Non-standard settings
checkconfigs = {"build", "config-plain"}
checkdeps    = { }
checkengines = {"pdftex", "xetex", "luatex", "ptex", "uptex"}
cleanfiles   = {"*.pdf", "*.tex", "*.zip"}
installfiles = {"l3build*.lua", "regression-test.tex"}
packtdszip   = true
sourcefiles  = {"*.dtx", "l3build*.lua", "*.ins"}
typesetcmds  = "\\AtBeginDocument{\\DisableImplementation}"
unpackdeps   = { }
tagfiles     = {"l3build.dtx", "*.md", "l3build.lua"}

-- Detail how to set the version automatically
function update_tag(file,content,tagname,tagdate)
  if string.match(file, "%.dtx$") then
    return string.gsub(content,
      "\n%% \\date{Released %d%d%d%d%-%d%d%-%d%d}\n",
      "\n%% \\date{Released " .. tagname .. "}\n")
  elseif string.match(file, "%.md$") then
    return string.gsub(content,
      "\nRelease %d%d%d%d%-%d%d%-%d%d\n",
      "\nRelease " .. tagname .. "\n")
  elseif string.match(file, "%.lua$") then
    return string.gsub(content,
      '\nrelease_date = "%d%d%d%d%-%d%d%-%d%d"\n',
      '\nrelease_date = "' .. tagname .. '"\n')
  end
  return contents
end

function setversion_update_line(line, date, version)
  local date = string.gsub(date, "%-", "/")
  -- .dtx file
  if string.match(line, "^%% \\date{Released %d%d%d%d/%d%d/%d%d}$") then
    line = string.gsub(line, "%d%d%d%d/%d%d/%d%d", date)
  end
  -- Markdown files
  if string.match(
    line, "^Release %d%d%d%d/%d%d/%d%d$"
  ) then
    line = "Release " .. date
  end
  -- l3build.lua
  if string.match(line, "^release_date = \"%d%d%d%d/%d%d/%d%d\"$") then
    line = "release_date = \"" .. date .. "\""
  end
  return line
end

-- Load l3build itself: truly self-contained so no kpsewhich() here
dofile("./l3build.lua")
