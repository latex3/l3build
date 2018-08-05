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
tagfiles     = {"l3build.1", "l3build.dtx", "*.md", "l3build.lua"}

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
      "\nRelease " .. iso .. "\n",
      "\nRelease " .. tagname .. "\n")
  elseif string.match(file, "%.lua$") then
    return string.gsub(content,
      '\nrelease_date = "' .. iso .. '"\n',
      '\nrelease_date = "' .. tagname .. '"\n')
  end
  return content
end

function tag_hook(tagname)
  os.execute('git commit -a -m "Step release tag"')
  os.execute('git tag -a -m "" ' .. tagname)
end


-- ctan upload settings
ctan_pkg="l3build"
ctan_version=[[2018/05/20]]
ctan_author=[[latex3 project]]


-- ctan_email='me@example.com'

-- some people may not want to reveal email in checked in files
-- email (or other fields) may be set by suitable function, eg
local handle = io.popen('git config user.email')
ctan_email = string.gsub(handle:read("*a"),'%s*$','')
handle:close()


ctan_uploader=[[me]]
ctan_ctanPath=[[]]
ctan_license="lppl"

-- ctan_sumary  is mandatory: not setting it will trigger interaction

ctan_announcement='ask'  -- this is optional: setting it to "ask" forces interaction

ctan_update=true

ctan_note=[[
this
is
a note
just to myself
]]

ctan_file="l3build.zip"

ctanupload="ask"


-- end of ctan upload settings

if not release_date then
  dofile("./l3build.lua")
end