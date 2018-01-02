--[[

File l3build.lua Copyright (C) 2014-2017 The LaTeX3 Project

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


--[[
      L3BUILD SETVERSION
      ==================
--]]

-- Provide some standard search-and-replace functions
if versionform ~= "" and not setversion_update_line then
  if versionform == "ProvidesPackage" then
    function setversion_update_line(line, date, version)
      -- No real regex so do it one type at a time
      for _,i in pairs({"Class", "File", "Package"}) do
        if match(
          line,
          "^\\Provides" .. i .. "{[a-zA-Z0-9%-%.]+}%[[^%]]*%]$"
        ) then
          line = gsub(line, "%[%d%d%d%d/%d%d/%d%d", "["
            .. gsub(date, "%-", "/"))
          line = gsub(
            line, "(%[%d%d%d%d/%d%d/%d%d) [^ ]*", "%1 " .. version
          )
          break
        end
      end
      return line
    end
  elseif versionform == "ProvidesExplPackage" then
    function setversion_update_line(line, date, version)
      -- No real regex so do it one type at a time
      for _,i in pairs({"Class", "File", "Package"}) do
        if match(
          line,
          "^\\ProvidesExpl" .. i .. " *{[a-zA-Z0-9%-%.]+}"
        ) then
          line = gsub(
            line,
            "{%d%d%d%d/%d%d/%d%d}( *){[^}]*}",
            "{" .. gsub(date, "%-", "/") .. "}%1{" .. version .. "}"
          )
          break
        end
      end
      return line
    end
  elseif versionform == "filename" then
    function setversion_update_line(line, date, version)
      if match(line, "^\\def\\filedate{%d%d%d%d/%d%d/%d%d}$") then
        line = "\\def\\filedate{" .. gsub(date, "%-", "/") .. "}"
      end
      if match(line, "^\\def\\fileversion{[^}]+}$") then
        line = "\\def\\fileversion{" .. version .. "}"
      end
      return line
    end
  elseif versionform == "ExplFileDate" then
    function setversion_update_line(line, date, version)
      if match(line, "^\\def\\ExplFileDate{%d%d%d%d/%d%d/%d%d}$") then
        line = "\\def\\ExplFileDate{" .. gsub(date, "%-", "/") .. "}"
      end
      if match(line, "^\\def\\ExplFileVersion{[^}]+}$") then
        line = "\\def\\ExplFileVersion{" .. version .. "}"
      end
      return line
    end
  end
end

-- Used to actually carry out search-and-replace
setversion_update_line = setversion_update_line or function(line, date, version)
  return line
end

function setversion()
  local function rewrite(dir, file, date, version)
    local changed = false
    local result = ""
    for line in io.lines(dir .. "/" .. file) do
      local newline = setversion_update_line(line, date, version)
      if newline ~= line then
        line = newline
        changed = true
      end
      result = result .. line .. os_newline
    end
    if changed then
      -- Avoid adding/removing end-of-file newline
      local f = open(dir .. "/" .. file, "rb")
      local content = f:read("*all")
      close(f)
      if not match(content, os_newline .. "$") then
        gsub(result, os_newline .. "$", "")
      end
      -- Write the new file
      ren(dir, file, file .. bakext)
      local f = open(dir .. "/" .. file, "w")
      output(f)
      write(result)
      close(f)
      rmfile(dir, file .. bakext)
    end
  end
  local date = options["date"] or os.date("%Y-%m-%d")
  local version = options["version"] or -1
  for _,dir in pairs(remove_duplicates({currentdir, sourcefiledir, docfiledir})) do
    for _,i in pairs(versionfiles) do
      for file,_ in pairs(tree(dir, i)) do
        rewrite(dir, file, date, version)
      end
    end
  end
  return 0
end

