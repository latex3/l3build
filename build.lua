#!/usr/bin/env texlua

-- Build script for LaTeX3 "l3build" files

-- Identify the bundle and module
module = "l3build"
bundle = ""

-- Non-standard settings
checkconfigs = {"build", "config-pdf", "config-plain"}
checkdeps    = { }
checkengines = {"pdftex", "xetex", "luatex", "ptex", "uptex"}
cleanfiles   = {"*.pdf", "*.tex", "*.zip"}
installfiles = {"regression-test.tex"}
packtdszip   = true
scriptfiles  = {"l3build*.lua"}
scriptmanfiles = {"l3build.1"}
sourcefiles  = {"*.dtx", "l3build*.lua", "*.ins"}
typesetcmds  = "\\AtBeginDocument{\\DisableImplementation}"
unpackdeps   = { }
tagfiles     = {"l3build.1", "l3build.dtx", "*.md", "l3build.lua", "build.lua"}

uploadconfig = {
  version     = "2018-12-17",
  author      = "The LaTeX Team",
  license     = "lppl1.3c",
  summary     = "A testing and building system for (La)TeX",
  topics      = {"Macro support", "Package development"},
  ctanPath    = "/macros/latex/contrib/l3build",
  repository  = "https://github.com/latex3/l3build/",
  bugtracker  = "https://github.com/latex3/l3build/issues",
  description = [[
The build system supports testing and building (La)TeX code, on
Linux, macOS, and Windows systems. The package offers:
* A unit testing system for (La)TeX code;
* A system for typesetting package documentation; and
* An automated process for creating CTAN releases.
  ]]
}

-- Detail how to set the version automatically
function update_tag(file,content,tagname,tagdate)
  local iso = "%d%d%d%d%-%d%d%-%d%d"
  local url = "https://github.com/latex3/l3build/compare/"
  if string.match(file, "%.1$") then
    return string.gsub(content,
      '%.TH l3build 1 "' .. iso .. '"\n',
      '.TH l3build 1 "' .. tagname .. '"\n')
  elseif string.match(file, "%.dtx$") then
    return string.gsub(content,
      "\n%% \\date{Released " .. iso .. "}\n",
      "\n%% \\date{Released " .. tagname .. "}\n")
  elseif string.match(file, "%.md$") then
    if string.match(file,"CHANGELOG.md") then
      local previous = string.match(content,"compare/(" .. iso .. ")%.%.%.HEAD")
      if tagname == previous then return content end
      content = string.gsub(content,
        "## %[Unreleased%]",
        "## [Unreleased]\n\n## [" .. tagname .."]")
      return string.gsub(content,
        iso .. "%.%.%.HEAD",
        tagname .. "...HEAD\n[" .. tagname .. "]: " .. url .. previous
          .. "..." .. tagname)
    end
    return string.gsub(content,
      "\nRelease " .. iso     .. "\n",
      "\nRelease " .. tagname .. "\n")
  elseif string.match(file, "build.lua$") then
    return string.gsub(content,
      '\n  version     = "' .. iso     .. '",\n',
      '\n  version     = "' .. tagdate .. '",\n')
  elseif string.match(file, "%.lua$") then
    return string.gsub(content,
      '\nrelease_date = "' .. iso     .. '"\n',
      '\nrelease_date = "' .. tagname .. '"\n')
  end
  return content
end

function tag_hook(tagname)
  os.execute('git commit -a -m "Step release tag"')
  os.execute('git tag -a -m "" ' .. tagname)
end

if not release_date then
  dofile("./l3build.lua")
end
