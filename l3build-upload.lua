--[[

File l3build-ctan-post.lua Copyright (C) 2018 The LaTeX3 Project

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


-- UPLOAD()
--
-- takes a package configuration table and an optional boolean
--
-- if the upload parameter is not supplied or is not true, only package validation
-- is used, if upload is true then package upload will be attempted if validation
-- succeeds.

-- fields are given as a string, or optionally for fields allowing multiple
-- values, as a table of strings.

-- Mandatory fields are checked in Lua
-- Maximum string lengths are checked.

-- Currently string values are not checked, eg licence names, or URL syntax.

-- The input form could be used to construct a post body but
-- luasec is not included in texlua. Instead an external program is used to post.
-- As Windows (since April 2018) includes curl now use curl.
-- A version using ctan-o-mat is available in the ctan-post github repo.

-- the main interface is
--     upload()
-- with a configuration table `uploaddata`


local curl_debug = curl_debug or false -- to disable posting

local ctanupload = ctanupload or "ask"
-- if ctanupload is nil or false, only validation is attempted
-- if ctanupload is true the ctan upload URL will be used after validation
-- if upload is anything else, the user will be prompted whether to upload.

function upload()

  -- try a sensible default for the package name:
  local bundle = bundle or ""
  if bundle == "" then
    bundle = nil
  end
  uploaddata.pkg = uploaddata.pkg or bundle or module or nil

  ctan_post = uploadexe .. " "

  --         field                                   max  desc                               mandatory  multi
  --         -------------------------------------------------------------------------------------------------
  ctan_field("pkg",          uploaddata.pkg,            32, "Package name",                        true,  false )
  ctan_field("version",      uploaddata.version,        32, "Package version",                     true,  false )
  ctan_field("author",       uploaddata.author,        128, "Author name",                         true,  false )
  ctan_field("email",        uploaddata.email,         255, "Email of uploader",                   true,  false )
  ctan_field("uploader",     uploaddata.uploader,      255, "Name of uploader",                    true,  false )
  ctan_field("ctanPath",     uploaddata.ctanPath,      255, "CTAN path",                           false, false )
  ctan_field("license",      uploaddata.license,      2048, "Package license(s); see https://ctan.org/license", true,  true )
  ctan_field("home",         uploaddata.home,          255, "URL of home page",                    false, false )
  ctan_field("bugtracker",   uploaddata.bugtracker,    255, "URL of bug tracker",                  false, false )
  ctan_field("support",      uploaddata.support,       255, "URL of support channels",             false, true  )
  ctan_field("repository",   uploaddata.repository,    255, "URL of source repositories",          false, true  )
  ctan_field("development",  uploaddata.development,   255, "URL of development channels",         false, true  )
  ctan_field("update",       uploaddata.update,          8, "Boolean: true for an update false otherwise",     false, false )
  ctan_field("topic",        uploaddata.topic,        1024, "Topic(s); see https://ctan.org/topics/highscore", false, true  )
  ctan_field("announcement", uploaddata.announcement, 8192, "Announcement",                        false, false )
  ctan_field("summary",      uploaddata.summary,       128, "One-line summary of package",         true,  false ) -- ctan-o-mat doc says optional
  ctan_field("description",  uploaddata.description,  4096, "Short description of package",        false, false )
  ctan_field("note",         uploaddata.note,         4096, "Internal note to ctan",               false, false )

  --[[
       Q: What about an explicit copyright string? CTAN packages have them
          listed. TODO: check these are all the fields.
  --]]

  -- construct the curl command
  ctan_post = ctan_post .. " --form 'file=@" .. tostring(ctan_file) .. ";filename=" .. tostring(ctan_file) .. "'"
  ctan_post = ctan_post ..  " https://ctan.org/submit/"

  -- avoid lower level error from post command if zip file missing
  local zip=io.open(trim_space(tostring(ctan_file)),"r")
  if zip~=nil then
    io.close(zip)
  else
    error("Missing zip file " .. tostring(ctan_file))
  end

  -- call post command to validate the upload at CTAN's validate URL
  local exit_status=0
  local fp_return=""

  -- use popen not execute so get the return body local exit_status=os.execute(ctan_post .. "validate")
  if (curl_debug==false) then
    local fp = assert(io.popen(ctan_post .. "validate", 'r'))
    fp_return = assert(fp:read('*a'))
    fp:close()
  else
    fp_return="WARNING: curl_debug==true: posting disabled"
    print(ctan_post)
  end
  if string.match(fp_return,"WARNING") or string.match(fp_return,"ERROR") then
    exit_status=1
  end

  -- if upload requested and validation succeeded repost to the upload URL
  if (exit_status==0 or exit_status==nil) then
    if (ctanupload ~=nil and ctanupload ~=false and ctanupload ~= true) then
      print("Validation successful, do you want to upload to CTAN?" )
      local answer=""
      io.write("> ")
      io.flush()
      answer=io.read()
      if(string.lower(answer,1,1)=="y") then
        ctanupload=true
      end
    end
    if (ctanupload==true) then
      local fp = assert(io.popen(ctan_post .. "upload", 'r'))
      fp_return = assert(fp:read('*a'))
      fp:close()
--     this is just html, could save to a file
--     or echo a cleaned up version
      print('Response from CTAN:')
      print(fp_return)
      if string.match(fp_return,"WARNING") or string.match(fp_return,"ERROR") then
        exit_status=1
      end
    else
      print("CTAN validation successful")
    end
  else
    error("Warnings from CTAN package validation:\n" .. fp_return)
  end
  return exit_status
end


function trim_space(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end


function ctan_field(fname,fvalue,max,desc,mandatory,multi)
  if (type(fvalue)=="table" and multi==true) then
    for i, v in pairs(fvalue) do
      ctan_single_field(fname,v,max,desc,mandatory and i==1)
    end
  else
    ctan_single_field(fname,fvalue,max,desc,mandatory)
  end
end


function ctan_single_field(fname,fvalue,max,desc,mandatory)
  print('ctan-post: ' .. fname .. ' ' ..tostring(fvalue or '??'))
  if ((fvalue==nil and mandatory) or (fvalue == 'ask')) then
    if (max < 256) then
      fvalue=input_single_line_field(fname)
      else
        fvalue=input_multi_line_field(fname)
    end
  end
  if (fvalue==nil or type(fvalue)~="table") then
    local vs=trim_space(tostring(fvalue))
    if (mandatory==true and (fvalue == nil or vs=="")) then
      error("The field " .. fname .. " must contain " .. desc)
    end
    if (fvalue ~=nil and string.len(vs) > 0) then
      if (max > 0 and string.len(vs) > max) then
        error("The field " .. fname .. " is longer than " .. max)
      end
      vs = vs:gsub('"','\\"')
      vs = vs:gsub('`','\\`')
      ctan_post=ctan_post .." --form " .. fname .. '="' .. vs .. '"'
    end
  else
    error("The value of the field '" .. fname .."' must be a scalar not a table")
  end
end


-- function for interactive multiline fields
function input_multi_line_field (name)
  print("Enter " .. name .. "  three <return> or ctrl-D to stop")

  local field=""

  local answer_line
  local return_count=0
  repeat
    io.write("> ")
    io.flush()
    answer_line=io.read()
    if answer_line=="" then
      return_count=return_count+1
    else
      for i=1,return_count,1 do
        field = field .. "\n"
      end
      return_count=0
      if answer_line~=nil then
        field = field .. "\n" .. answer_line
      end
     end
  until (return_count==3 or answer_line==nil)
  return field
end

function input_single_line_field(name)
  print("Enter " .. name )

  local field=""

  io.write("> ")
  io.flush()
  field=io.read()
  return field
end

