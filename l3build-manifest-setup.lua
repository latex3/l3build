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
      L3BUILD MANIFEST SETUP
      ======================
      This file contains all of the code that is easily replaceable by the user.
      Either create a copy of this file, rename, and include alongside your `build.lua`
      script and load it with `dofile()`, or simply copy/paste the definitions below
      into your `build.lua` script directly.
--]]


--[[
      Setup of manifest "groups"
      --------------------------
--]]

manifest_setup = manifest_setup or function()
  local groups = {
    {
       name    = "Source files",
       description = [[
These are source files for a number of purposes, including the `unpack`
process which generates the installation files of the package. Additional
files included here will also be installed for processing such as testing.
       ]],
       files   = {sourcefiles},
    },
    {
       name    = "Typeset documentation source files",
       description = [[
These files are typeset using LaTeX to produce the PDF documentation for the package.
       ]],
       files   = {typesetfiles,typesetsourcefiles,typesetdemofiles},
    },
    {
       name    = "Documentation files",
       description = [[
These files form part of the documentation but are not typeset.
Generally they will be additional input files for the typeset
documentation files listed above.
       ]],
       files   = {docfiles},
    },
    {
       name    = "Text files",
       files   = {textfiles},
       extractfiledesc = false,
    },
    {
       name    = "Demo files",
       files   = {demofiles},
    },
    {
       name    = "Bibliography and index files",
       files   = {bibfiles,bstfiles,makeindexfiles},
    },
    {
       name    = "Derived files",
       files   = {installfiles},
       exclude = {excludefiles,sourcefiles},
       dir     = unpackdir,
       extractfiledesc = false,
    },
    {
       name    = "Typeset documents",
       files   = {typesetfiles,typesetsourcefiles,typesetdemofiles},
       rename  = {"%.%w+$", ".pdf"},
    },
    {
       name    = "Support files needed for unpacking, typesetting, or checking",
       files   = {unpacksuppfiles,typesetsuppfiles,checksuppfiles},
       dir     = supportdir,
    },
    {
       name    = "Checking-specific support files",
       files   = {"*.*"},
       exclude = {{".",".."},excludefiles},
       dir     = testsuppdir,
    },
    {
       name    = "Test files",
       description = [[
These files form the test suite for the package.
`.lvt` or `.lte` files are the individual unit tests,
and `.tlg` are the stored output for ensuring changes
to the package produce the same output. These output
files are sometimes shared and sometime specific for
different engines (pdfTeX, XeTeX, LuaTeX, etc.).
       ]],
       files   = {"*"..lvtext,"*"..lveext,"*"..tlgext},
       dir     = testfiledir,
       extractfiledesc = false,
    },
  }
  return groups
end

--[[
      Sorting within groups
      ---------------------
--]]

manifest_sort_within_match = manifest_sort_within_match or function(files)
  local f = files
  table.sort(f)
  return f
end

manifest_sort_within_group = manifest_sort_within_group or function(files)
  local f = files
  --[[
      -- no-op by default; make your own definition to customise. E.g.:
      table.sort(f)
  --]]
  return f
end

--[[
      Writing to file
      ---------------
--]]

manifest_write_opening = manifest_write_opening or function(filehandle)

  filehandle:write("# Manifest for " .. module .. "\n\n")
  filehandle:write("This file is automatically generated with `texlua build.lua manifest`.\n")

end

manifest_write_group_heading = manifest_write_group_heading or function (filehandle,heading)

   filehandle:write("\n## " .. heading .. "\n\n")

end

manifest_write_group_description = manifest_write_group_description or function(filehandle,description)
-- Redefine as a no-op if you don't like each group to have a written description.

  filehandle:write(description .. "\n")

end

manifest_write_group_file = manifest_write_group_file or function(filehandle,count,filename,Nchar)
  --[[
        filehandle : write file object
             count : the count of the filename to be written
          filename : the name of the file to write
             Nchar : the maximum number of chars of all filenames in this group
  --]]

  -- no file description: plain bullet list item:
  filehandle:write("* " .. filename .. "\n")

  --[[
    -- or if you prefer an enumerated list:
    filehandle:write(count..". " .. filename .. "\n")
  --]]


end

manifest_write_group_file_descr = manifest_write_group_file_descr or function(filehandle,count,filename,Nchar,descr,NcharD)
  --[[
        filehandle : write file object
             count : the count of the filename to be written
          filename : the name of the file to write
             Nchar : the maximum number of chars of all filenames in this group
             descr : description of the file to write
            NcharD : the maximum number of chars of all descriptions in this group
  --]]

  -- filename+description: Github-flavoured Markdown table

  if count==1 then
    -- header of table
    manifest_write_group_file_descr(filehandle,-1,"File",Nchar,"Description",NcharD)
    manifest_write_group_file_descr(filehandle,-1,"---", Nchar,"---",        NcharD)
  end

  filehandle:write(string.format(
    "  | %-"..Nchar .."s | %-"..NcharD.."s |\n",
    filename,descr))

end

--[[
      Extracting ‘descriptions’ from source files
      -------------------------------------------
--]]

manifest_extract_filedesc = manifest_extract_filedesc or function(filehandle)
-- no-op by default; two examples below
end

--[[

-- From the first match of a pattern in a file:
manifest_extract_filedesc = function(filehandle)

  local read_string   = "*all"
  local matchstr      = "\\section{(.-)}"

  all_file = filehandle:read(read_string)

  return string.match(all_file,matchstr)

end

-- From the match of the 2nd line (say) of a file:
manifest_extract_filedesc = function(filehandle)

  local end_read_loop = 2
  local read_string   = "*line"
  local matchstr      = "%%%S%s+(.*)"
  local this_line     = ""

  for ii = 1, end_read_loop do
    this_line = filehandle:read(read_string)
  end

  return string.match(this_line,matchstr)

end

]]--
