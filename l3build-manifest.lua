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
      L3BUILD MANIFEST
      ================
      If desired this entire function can be replaced; if not, it uses a number of
      auxiliary functions which are included in this file.

      Additional setup can be performed by replacing the functions lists in the file
      `l3build-manifest-setup.lua`.
--]]

manifest = manifest or function()

  local manifest_entries = manifest_setup()

  for ii,_ in ipairs(manifest_entries) do
    manifest_entries[ii] = manifest_build_list(manifest_entries[ii])
  end

  manifest_write(manifest_entries)

  printline = "Manifest written to " .. manifestfile
  print((printline:gsub(".","*")))  print(printline)  print((printline:gsub(".","*")))

end

--[[
      Internal Manifest functions: build_list
      ---------------------------------------
--]]

manifest_build_list = function(entry)

  entry = manifest_build_init(entry)

  -- build list of excluded files
  for _,glob_list in ipairs(entry.exclude) do
    for _,this_glob in ipairs(glob_list) do
      for _,this_file in ipairs(filelist(maindir,this_glob)) do
        entry.excludes[this_file] = true
      end
    end
  end

  -- build list of matched files
  for _,glob_list in ipairs(entry.files) do
    for _,this_glob in ipairs(glob_list) do

      local these_files = filelist(entry.dir,this_glob)
      these_files = manifest_sort_within_match(these_files)

      for _,this_file in ipairs(these_files) do
        entry = manifest_build_file(entry,this_file)
      end

      entry.files_ordered = manifest_sort_within_group(entry.files_ordered)

    end
  end

  return entry

end


manifest_build_init = function(entry)

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
    excludes      = {} ,
    files_ordered = {} ,
    descr         = {} ,
    Nchar_file    = 4  , -- TODO: generalise
    Nchar_descr   = 11 , -- TODO: generalise
  }

   -- copy default options to each group if necessary
  for kk,ll in pairs(manifest_group_defaults) do
    entry[kk] = entry[kk] or ll
  end

  -- initialisation for internal data
  for kk,ll in pairs(manifest_group_init) do
    entry[kk] = ll
  end

  -- allow nested tables by requiring two levels of nesting
  if type(entry.files[1])=="string" then
    entry.files = {entry.files}
  end
  if type(entry.exclude[1])=="string" then
    entry.exclude = {entry.exclude}
  end

  return entry

end


manifest_build_file = function(entry,this_file)

  -- rename?
  if entry.rename then
    this_file:gsub(entry.rename[1], entry.rename[2])
  end

  if not entry.excludes[this_file] then

    entry.N = entry.N+1
    if not(entry.matches[this_file]) then

      entry.matches[this_file] = true -- store the file name
      entry.files_ordered[entry.N] = this_file -- store the file order

      entry.Nchar_file = math.max( entry.Nchar_file , this_file:len() )

    end

    if not(entry.rename) and entry.extractfiledesc then

      local ff = assert(io.open(entry.dir .. "/" .. this_file, "r"))
      this_descr = manifest_extract_filedesc(ff)
      ff:close()

      if this_descr and this_descr ~= "" then

        entry.descr[this_file] = this_descr
        entry.ND = entry.ND+1
        entry.Nchar_descr = math.max( entry.Nchar_descr, this_descr.len() )

      end
    end
  end

  return entry

end

--[[
      Internal Manifest functions: write
      ----------------------------------
--]]

manifest_write = function(manifest_entries)

  local f = assert(io.open(manifestfile, "w"))
  manifest_write_opening(f)

  for ii,vv in ipairs(manifest_entries) do
    if manifest_entries[ii].N > 0 then
      manifest_write_group(f,manifest_entries[ii])
    end
  end

  f:close()

end


manifest_write_group = function(f,entry)

  manifest_write_group_heading(f,entry.name)

  if entry.description then
    manifest_write_group_description(f,entry.description)
  end

  if not(entry.rename) and entry.extractfiledesc and entry.ND > 0 then

    local C = 0
    for _,file in ipairs(entry.files_ordered) do
      C = C+1
      descr = entry.descr[file] or ""
      manifest_write_group_file_descr(f,C,file,entry.Nchar_file,descr,entry.Nchar_descr)
    end

  else

    local C = 0
    for _,ff in ipairs(entry.files_ordered) do
      C = C+1
      manifest_write_group_file(f,C,ff,entry.Nchar_file)
    end

  end

end

