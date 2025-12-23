-- Build script for LaTeX "l3build" files

-- Identify the bundle and module
module = "l3build"
bundle = ""

-- Non-standard settings
checkconfigs = {"build", "config-pdf", "config-plain","config-context", "config-tagging"}
checkdeps    = { }
checkengines = {"pdftex", "xetex", "luatex", "ptex", "uptex"}
cleanfiles   = {"*.pdf", "*.tex", "*.zip"}
exefiles     = {"l3build.lua"}
installfiles = {"regression-test.tex"}
packtdszip   = true
scriptfiles  = {"l3build*.lua"}
scriptmanfiles = {"l3build.1"}
sourcefiles  = {"*.dtx", "l3build*.lua", "*.ins"}
typesetruns  = 4
typesetcmds  = "\\AtBeginDocument{\\DisableImplementation}"
unpackdeps   = { }
tagfiles     = {
  "l3build.1",
  "l3build.dtx",
  "l3build.ins",
  "**/*.md",     -- to include README.md in ./examples
  "l3build*.lua",
  "**/regression-test.cfg"
}

uploadconfig = {
  author      = "The LaTeX Team",
  license     = "lppl1.3c",
  summary     = "A testing and building system for (La)TeX",
  topic       = {"macro-supp", "package-devel"},
  ctanPath    = "/macros/latex/contrib/l3build",
  repository  = "https://github.com/latex3/l3build/",
  bugtracker  = "https://github.com/latex3/l3build/issues",
  update      = true,
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
  -- update copyright
  local year = os.date("%Y")
  local oldyear = math.tointeger(year - 1)
  if string.match(content,"%(C%)%s*" .. oldyear .. " The LaTeX Project") then
    content = string.gsub(content,
      "%(C%)%s*" .. oldyear .. " The LaTeX Project",
      "(C) " .. year .. " The LaTeX Project")
  elseif string.match(content,"%(C%)%s*%d%d%d%d%-" .. oldyear .. " The LaTeX Project") then
    content = string.gsub(content,
      "%(C%)%s*(%d%d%d%d%-)" .. oldyear .. " The LaTeX Project",
      "(C) %1" .. year .. " The LaTeX Project")
  end
  -- update release date
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
  elseif string.match(file, "%.lua$") then
    return string.gsub(content,
      '\nrelease_date = "' .. iso     .. '"\n',
      '\nrelease_date = "' .. tagname .. '"\n')
  end
  return content
end

function tag_hook(tagname)
  os.execute('git commit -a -m "Step release tag"')
end

-- Auto-generate a .1 file from the help
function  docinit_hook()
  local find = string.find
  local insert = table.insert
  local open = io.open

  ---@type file*?
  local f = assert(open("README.md","rb"))
  ---@cast f file*
  local readme = f:read("a")
  f:close()
  f = nil

  local date_start,date_end = find(readme,"%d%d%d%d%p%d%d%p%d%d")

  local man_t = {}
  insert(man_t,'.TH ' .. string.upper(module) .. ' 1 "'
    .. readme:sub(date_start,date_end) .. '" "LaTeX"\n')
  insert(man_t,(".SH NAME\n" .. module .. "\n"))
  insert(man_t,(".SH SYNOPSIS\n Usage " .. module .. " <target> [<options>] [<names>]\n"))
  insert(man_t,".SH DESCRIPTION")

  local _,desc_start = find(readme,"Overview\n--------")
  local desc_end,_ = find(readme,"Issues")

  local overview = readme:sub(desc_start + 8,desc_end - 2):gsub("[_]",""):gsub("`",'"'):gsub("[*] ","\n * ")
  insert(man_t,overview)

  local cmd = "texlua ./" .. module .. ".lua --help"
  f = assert(io.popen(cmd,"r"))
  local help_text = assert(f:read("a"))
  f:close()
  f = nil

  insert(man_t,(help_text:gsub("\nUsage.*names>]\n\n","")
  :gsub("Valid targets",".SH COMMANDS\nValid targets")
  :gsub("Valid options",".SH OPTIONS\nValid options")
  :gsub("Full manual",'.SH "SEE ALSO"\nFull manual')
  :gsub("Bug tracker","\nBug tracker")
  :gsub("Copyright",".SH AUTHORS\nCopyright")))

  f = assert(open(module .. ".1","wb"))
  f:write((table.concat(man_t,"\n"):gsub("\n$","")))
  f:close()
  return 0
end

if not release_date then
  dofile("./l3build.lua")
end
