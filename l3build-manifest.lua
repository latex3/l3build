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

  manifest_lists = manifest_setup()

  for ii,_ in ipairs(manifest_lists) do
    manifest_lists[ii] = manifest_build_list(manifest_lists[ii])
  end

  manifest_write(manifest_lists)

  printline = "Manifest written to " .. manifestfile
  print((printline:gsub(".","*")))  print(printline)  print((printline:gsub(".","*")))

end

--[[
      Internal Manifest functions: build_list
      ---------------------------------------
--]]

manifest_build_list = function(manifest_list)

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


manifest_build_init = function(manifest_list)

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


--[[
      Internal Manifest functions: write
      ----------------------------------
--]]

manifest_write = function(manifest_lists)

  local f = assert(io.open(manifestfile, "w"))
  manifest_write_opening(f)

  for ii,vv in ipairs(manifest_lists) do
    if manifest_lists[ii].N > 0 then
      manifest_write_group(f,manifest_lists[ii])
    end
  end

  f:close()

end


manifest_write_group = function(f,manifest_list)

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

