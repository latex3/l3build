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


manifest = manifest or function()

  manifest_lists = manifest_setup()

  for ii,_ in ipairs(manifest_lists) do
    manifest_lists[ii] = manifest_build_list(manifest_lists[ii])
  end

  manifest_write(manifest_lists)

end



manifest_setup = manifest_setup or function()
-- this needs to be an array of tables, not a table of tables, to ensure ordering.
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




manifest_build_list = manifest_build_list or function(manifest_list)

  manifest_list = manifest_build_init(manifest_list)

  -- build list of excluded files
  local excludelist = {}
  for _,glob_list in ipairs(manifest_list.exclude) do
    for _,this_glob in ipairs(glob_list) do
      for _,this_file in ipairs(filelist(maindir,this_glob)) do
        excludelist[this_file] = true
      end
    end
  end

  -- build list of matched files
  for _,glob_list in ipairs(manifest_list.files) do
    for _,this_glob in ipairs(glob_list) do

      local these_files = filelist(manifest_list.dir,this_glob)
      these_files = manifest_sort_within_glob(these_files)

      for _,this_file in ipairs(these_files) do

        -- rename?
        if manifest_list.rename then
          this_file = string.gsub(this_file, manifest_list.rename[1], manifest_list.rename[2])
        end

        if not excludelist[this_file] then

          manifest_list.N = manifest_list.N+1
          if not(manifest_list.matches[this_file]) then

            manifest_list.matches[this_file] = true -- store the file name
            manifest_list.files_ordered[manifest_list.N] = this_file -- store the file order

            manifest_list.Nchar_file =
              math.max( manifest_list.Nchar_file , string.len(this_file) )

          end

          if not(manifest_list.rename) and manifest_list.extractfiledesc then

            local ff = assert(io.open(manifest_list.dir .. "/" .. this_file, "r"))
            this_descr = manifest_extract_filedesc(ff)
            ff:close()

            if this_descr and this_descr ~= "" then

              manifest_list.descr[this_file] = this_descr
              manifest_list.ND = manifest_list.ND+1
              manifest_list.Nchar_descr =
                math.max(
                  manifest_list.Nchar_descr,
                  string.len(this_descr)
                )

            end
          end
        end
      end

      manifest_list.files_ordered = manifest_sort_within_group(manifest_list.files_ordered)

    end
  end

  return manifest_list

end

manifest_build_init = manifest_build_init or function(manifest_list)

-- currently these aren't customisable; I guess they could/should be?
  local manifest_group_defaults = {
    extractfiledesc  = true           ,
    rename           = false          ,
    dir              = maindir        ,
    exclude          = {excludefiles} ,
  }

  -- internal data added to each group in the table that needs to be initialised
  local manifest_group_init = {
    N             = 0  , -- # matched files
    ND            = 0  , -- # descriptions
    matches       = {} ,
    files_ordered = {} ,
    descr         = {} ,
    Nchar_file    = 4  , -- TODO: generalise
    Nchar_descr   = 11 , -- TODO: generalise
  }

   -- copy default options to each group if necessary
  for kk,ll in pairs(manifest_group_defaults) do
    manifest_list[kk] = manifest_list[kk] or ll
  end

  -- initialisation for internal data
  for kk,ll in pairs(manifest_group_init) do
    manifest_list[kk] = ll
  end

  -- allow nested tables by requiring two levels of nesting
  if type(manifest_list.files[1])=="string" then
    manifest_list.files = {manifest_list.files}
  end
  if type(manifest_list.exclude[1])=="string" then
    manifest_list.exclude = {manifest_list.exclude}
  end

  return manifest_list

end



manifest_write = manifest_write or function(manifest_lists)

  local f = assert(io.open(manifestfile, "w"))
  manifest_write_opening(f)

  for ii,vv in ipairs(manifest_lists) do
    if manifest_lists[ii].N > 0 then
      manifest_write_group(f,manifest_lists[ii])
    end
  end

  f:close()

  print("*******************************************")
  print("Manifest written to " .. manifestfile .. ".")
  print("*******************************************")

end


manifest_write_group = manifest_write_group or function(f,manifest_list)

  manifest_write_group_heading(f,manifest_list.name)

  if manifest_list.description then
    manifest_write_group_description(f,manifest_list.description)
  end

  if not(manifest_list.rename) and manifest_list.extractfiledesc and manifest_list.ND > 0 then

    local C = 0
    for _,file in ipairs(manifest_list.files_ordered) do
      C = C+1
      descr = manifest_list.descr[file] or ""
      manifest_write_group_file_descr(f,C,file,manifest_list.Nchar_file,descr,manifest_list.Nchar_descr)
    end

  else

    local C = 0
    for _,ff in ipairs(manifest_list.files_ordered) do
      C = C+1
      manifest_write_group_file(f,C,ff,manifest_list.Nchar_file)
    end

  end

end


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

manifest_sort_within_glob = manifest_sort_within_glob or function(files)
  table.sort(files)
  return files
end

manifest_sort_within_group = manifest_sort_within_group or function(files)
  --[[
      -- no-op by default; make your own definition to customise. E.g.:
      table.sort(files)
  --]]
  return files
end

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
