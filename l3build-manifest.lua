--[[

File l3build-manifest.lua Copyright (C) 2018-2023 The LaTeX Project

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

function manifest()

  -- build list of ctan files
  ctanfiles = {}
  for _,f in ipairs(filelist(ctandir.."/"..ctanpkg,"*.*")) do
    ctanfiles[f] = true
  end
  tdsfiles = {}
  for _,subdir in ipairs({"/doc/","/source/","/tex/"}) do
    for _,f in ipairs(filelist(tdsdir..subdir..moduledir,"*.*")) do
      tdsfiles[f] = true
    end
  end

  local manifest_entries = manifest_setup()

  for ii,_ in ipairs(manifest_entries) do
    manifest_entries[ii] = manifest_build_list(manifest_entries[ii])
  end

  manifest_write(manifest_entries)

  printline = "Manifest written to " .. manifestfile
  print((printline:gsub(".","*")))  print(printline)  print((printline:gsub(".","*")))

  return 0

end

--[[
      Internal Manifest functions: build_list
      ---------------------------------------
--]]

manifest_build_list = function(entry)

  if not(entry.subheading) then

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

	end

  return entry

end


manifest_build_init = function(entry)

  -- currently these aren't customisable; I guess they could be?
  local manifest_group_defaults = {
    skipfiledescription  = false          ,
    rename               = false          ,
    dir                  = maindir        ,
    exclude              = {excludefiles} ,
    flag                 = true           ,
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
    if entry[kk] == nil then
      entry[kk] = ll
    end
    -- can't use "entry[kk] = entry[kk] or ll" because false/nil are indistinguishable!
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

  if entry.rename then
    this_file = this_file:gsub(entry.rename[1],entry.rename[2])
  end

  if not entry.excludes[this_file] then

    entry.N = entry.N+1
    if not(entry.matches[this_file]) then

      entry.matches[this_file] = true -- store the file name
      entry.files_ordered[entry.N] = this_file -- store the file order
      entry.Nchar_file = math.max(entry.Nchar_file,this_file:len())

    end

    if not(entry.skipfiledescription) then

      local ff = assert(io.open(entry.dir .. "/" .. this_file, "r"))
      this_descr  = manifest_extract_filedesc(ff,this_file)
      ff:close()

      if this_descr and this_descr ~= "" then
        entry.descr[this_file] = this_descr
        entry.ND = entry.ND+1
        entry.Nchar_descr = math.max(entry.Nchar_descr,this_descr:len())
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
    if manifest_entries[ii].subheading then
      manifest_write_subheading(f,manifest_entries[ii].subheading,manifest_entries[ii].description)
    elseif manifest_entries[ii].N > 0 then
      manifest_write_group(f,manifest_entries[ii])
    end
  end

  f:close()

end


manifest_write_group = function(f,entry)

  manifest_write_group_heading(f,entry.name,entry.description)

  if entry.ND > 0 then

    for ii,file in ipairs(entry.files_ordered) do
      local descr = entry.descr[file] or ""
      local param = {
        dir         = entry.dir         ,
        count       = ii                ,
        filemaxchar = entry.Nchar_file  ,
        descmaxchar = entry.Nchar_descr ,
        ctanfile    = ctanfiles[file]   ,
        tdsfile     = tdsfiles[file]    ,
        flag        = false             ,
      }

      if entry.flag then
        param.flag = "    "
	  		if tdsfiles[file] and not(ctanfiles[file]) then
	  			param.flag = "†   "
	  		elseif ctanfiles[file] then
	  			param.flag = "‡   "
	  		end
			end

			if ii == 1 then
        -- header of table
        -- TODO: generalise
				local p = {}
				for k,v in pairs(param) do p[k] = v end
				p.count = -1
				p.flag = p.flag and "Flag"
				manifest_write_group_file_descr(f,"File","Description",p)
				p.flag = p.flag and "--- "
				manifest_write_group_file_descr(f,"---","---",p)
      end

      manifest_write_group_file_descr(f,file,descr,param)
    end

  else

    for ii,file in ipairs(entry.files_ordered) do
      local param = {
        dir         = entry.dir         ,
      	count       = ii                ,
      	filemaxchar = entry.Nchar_file  ,
        ctanfile    = ctanfiles[file]   ,
        tdsfile     = tdsfiles[file]    ,
      }
      if entry.flag then
        param.flag = ""
	  		if tdsfiles[file] and not(ctanfiles[file]) then
	  			param.flag = "†"
	  		elseif ctanfiles[file] then
	  			param.flag = "‡"
	  		end
			end
      manifest_write_group_file(f,file,param)
    end

  end

end
