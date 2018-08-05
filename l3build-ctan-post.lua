--[[

File l3build-unpack.lua Copyright (C) 2018 The LaTeX3 Project

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


-- ctan_upload
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
-- luasec is not included in texlua.

-- Instead an external program is used to post.
-- As Windows (since April 2018) includes curl now use curl.
-- a version using ctan-o-mat is available in the ctan-post github repo

-- the main interface is
-- ctan_upload ()
-- with a configuration table c and optional upload parameter


local ctan_post_command = ctan_post_command or "curl"
local curl_debug=false -- posting is disabled while testing



local ctanupload= ctanupload or "ask"
-- if ctanupload is nil or false, only validation is attempted
-- if ctanupload is true the ctan upload URL will be used  after validation
-- if upload is anything else, the user will be prompted whether to upload.



function ctan_upload ()

ctan_post=ctan_post_command .. " "


  --        field max desc                   mandatory multi
  --        ----------------------------------------------------
  ctan_field("pkg",ctan_pkg,32,"the package name",       true,false)
  ctan_field("version",ctan_version,32,"the package version",true,false)
  ctan_field("author",ctan_author,128,"the author name",    true,false)
  ctan_field("email",ctan_email,255,"the email of uploader",true,false)
  ctan_field("uploader",ctan_uploader,255,"the name of uploader",true,false)
  ctan_field("ctanPath",ctan_ctanPath,255,"the CTAN path",    false,false)
  ctan_field("license",ctan_license,2048,"Package License",  true,true)
  ctan_field("home",ctan_home,255,"URL of home page",     false,false)
  ctan_field("bugtracker",ctan_bugtracker,255,"URL of bug tracker",false,false)
  ctan_field("support",ctan_support,255,"URL of support channels",false,true)
  ctan_field("repository",ctan_repository,255,"URL of source repositories",false,true)
  ctan_field("development",ctan_development,255,"URL of development channels",false,true)
  ctan_field("update",ctan_update,8,",true for an update false otherwise",false,false)
  ctan_field("topic",ctan_topic,1024,"topic",              false,true)
  ctan_field("announcement",ctan_announcement,8192,"announcement",false,false)
  ctan_field("summary",ctan_summary,128,"summary",           true,false) -- ctan-o-mat doc says optional
  ctan_field("description",ctan_description,4096,"description",  false,false)
  ctan_field("note",ctan_note,4096,"internal note to ctan",false,false)


  ctan_post=ctan_post .. " --form 'file=@" .. tostring(ctan_file) .. ";filename=" .. tostring(ctan_file) .. "'"
  ctan_post=ctan_post ..  " https://ctan.org/submit/"



  -- avoid lower level error from post command if zip file missing
  local zip=io.open(trim_space(tostring(ctan_file)),"r")
  if zip~=nil then
    io.close(zip)
  else
    error("missing zip file " .. tostring(ctan_file))
  end

  -- call post command to validate the upload at CTAN's validate URL
  local exit_status=0
  local fp_return=""

--    use popen not execute so get the return body local exit_status=os.execute(ctan_post .. "validate")
  if(curl_debug==false) then
    local fp = assert(io.popen(ctan_post .. "validate", 'r'))
    fp_return = assert(fp:read('*a'))
    fp:close()
  else
   fp_return="WARNING: curl_debug==true: posting disabled disabled"
   print(ctan_post)
  end
  if string.match(fp_return,"WARNING") or string.match(fp_return,"ERROR") then
   exit_status=1
  end

  -- if upload requested and validation succeeded repost to the upload URL
  if (exit_status==0 or exit_status==nil) then
    if(ctanupload ~=nil and ctanupload ~=false and ctanupload ~= true) then
      print("Validation successful, do you want to upload to CTAN?" )
      local answer=""
      io.write("> ")
      io.flush()
      answer=io.read()
      if(string.lower(answer,1,1)=="y") then
        ctanupload=true
      end
    end
    if(ctanupload==true) then
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
  if(type(fvalue)=="table" and multi==true) then
    for i, v in pairs(fvalue) do
      ctan_single_field(fname,v,max,desc,mandatory and i==1)
    end
  else
    ctan_single_field(fname,fvalue,max,desc,mandatory)
  end
end


function ctan_single_field(fname,fvalue,max,desc,mandatory)
print('ctan-post: ' .. fname .. ' ' ..tostring(fvalue or '??'))
  if((fvalue==nil and mandatory) or (fvalue == 'ask')) then
    if (max < 256) then
      fvalue=input_single_line_field(fname)
      else
        fvalue=input_multi_line_field(fname)
    end      
  end
  if(fvalue==nil or type(fvalue)~="table") then
    local vs=trim_space(tostring(fvalue))
    if (mandatory==true and (fvalue == nil or vs=="")) then
      error("The field " .. fname .. " must contain " .. desc)
    end
    if(fvalue ~=nil and string.len(vs) > 0) then
      if (max > 0 and string.len(vs) > max) then
        error("The field " .. fname .. " is longer than " .. max)
      end
      ctan_post=ctan_post .." --form " .. fname .. '="' .. vs:gsub('"','\\"') .. '"'
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

