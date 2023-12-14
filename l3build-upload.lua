--[[

File l3build-upload.lua Copyright (C) 2018-2023 The LaTeX Project

It may be distributed and/or modified under the conditions of the
LaTeX Project Public License (LPPL), either version 1.3c of this
license or (at your option) any later version.  The latest version
of this license is in the file

   https://www.latex-project.org/lppl.txt

This file is part of the "l3build bundle" (The Work in LPPL)
and all files in that bundle must be distributed together.

-----------------------------------------------------------------------

The development version of the bundle can be found at

   https://github.com/latex3/l3build

for those people who are interested.

--]]

local pairs    = pairs
local print    = print
local tostring = tostring

local close = io.close
local flush = io.flush
local open  = io.open
local output = io.output
local popen = io.popen
local read  = io.read
local write = io.write

local os_type = os.type

local len   = string.len
local lower = string.lower
local match = string.match

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
-- with a configuration table `uploadconfig`


local curl_debug = curl_debug or false -- to disable posting
-- For now, this is undocumented.


if options["dry-run"] then
  ctanupload = false
end
-- if ctanupload is nil or false, only validation is attempted
-- if ctanupload is true the ctan upload URL will be used after validation
-- if upload is anything else, the user will be prompted whether to upload.
-- For now, this is undocumented. I think I would prefer to keep it always set to ask for the time being.

local ctan_post -- this is private to the module

-- TODO: next is a public global method,
-- but following functions are semantically local
-- despite they are declared globally.

function upload(tagnames)

  local uploadfile = ctanzip..".zip"

  -- Keep data local
  local uploadconfig = uploadconfig

  -- try a sensible default for the package name:
  uploadconfig.pkg = uploadconfig.pkg or ctanpkg or nil

  -- Get data from command line if appropriate
  if options["file"] then
    local f = open(options["file"],"r")
    uploadconfig.announcement = assert(f:read('*a'))
    close(f)
  end
  uploadconfig.announcement = options["message"] or uploadconfig.announcement or file_contents(uploadconfig.announcement_file)
  uploadconfig.email = options["email"] or uploadconfig.email


  uploadconfig.note =   uploadconfig.note  or file_contents(uploadconfig.note_file)

  tagnames = tagnames or { }
  uploadconfig.version = tagnames[1] or uploadconfig.version

  local override_update_check = false
  if uploadconfig.update == nil then
    uploadconfig.update = true
    override_update_check = true
  end

  -- avoid lower level error from post command if zip file missing
  local ziptime = lfs.attributes(trim_space(tostring(uploadfile)), 'modification')
  if not ziptime then
    error("Missing zip file '" .. tostring(uploadfile) .. "'. \z
       Maybe you forgot to run 'l3build ctan' first?")
  end
  local age = os.time() - ziptime
  if age >= 86400 then
    print(string.format("------------------------------------------\n\z
           | The local archive is older than %3i days.            |\n\z
           | Are you sure that you executed 'l3build ctan' first? |\n\z
           --------------------------------------------------------",
      age // 86400))
    print("Are you sure you want to continue? [y/n]" )
    io.stdout:write("> "):flush()
    if lower(read(),1,1) ~= "y" then
       print'Aborting'
       return 1
    end
  end

  ctan_post = construct_ctan_post(uploadfile,options["debug"])


-- curl file version
  local curloptfile = uploadconfig.curlopt_file or (ctanzip .. ".curlopt")
  local curlopt=open(curloptfile,"w")
  output(curlopt)
  write(ctan_post)
  close(curlopt)

  ctan_post=curlexe .. " --config " .. curloptfile


if options["debug"] then
    ctan_post = ctan_post ..  ' https://httpbin.org/post'
    fp_return = shell(ctan_post)
    print('\n\nCURL COMMAND:')
    print(ctan_post)
    print("\n\nHTTP RESPONSE:")
    print(fp_return)
    return 1
else
    ctan_post = ctan_post ..  ' https://ctan.org/submit/'
end

  -- call post command to validate the upload at CTAN's validate URL
  local exit_status=0
  local fp_return=""

  -- use popen not execute so get the return body local exit_status=os.execute(ctan_post .. "validate")
  if (curl_debug==false) then
    print("Contacting CTAN for validation:")
    fp_return = shell(ctan_post .. "validate")
  else
    fp_return="WARNING: curl_debug==true: posting disabled"
    print(ctan_post)
    return 1
  end
  if override_update_check then
    if match(fp_return,"non%-existent%spackage") then
      print("Package not found on CTAN; re-validating as new package:")
      uploadconfig.update = false
      ctan_post = construct_ctan_post(uploadfile)
      fp_return = shell(ctan_post .. "validate")
    end
  end
  if (match(fp_return,"ERROR")) then
    exit_status=1
  end

  -- if upload requested and validation succeeded repost to the upload URL
  if (exit_status==0 or exit_status==nil) then
    if (ctanupload ~=nil and ctanupload ~=false and ctanupload ~= true) then
      if (match(fp_return,"WARNING")) then
        print("Warnings from CTAN package validation:" .. fp_return:gsub("%[","\n["):gsub("%]%]","]\n]"))
      else
        print("Validation successful." )
      end
      print("" )
      if age < 86400 and age >= 60 then
        if age >= 3600 then
          print("----------------------------------------------------" )
          print(string.format("| The local archive is older than %2i hours.        |", age//3600 ))
          print("| Have you executed l3build ctan first?  If so ... |" )
          print("----------------------------------------------------" )
        else
          print(string.format("The local archive is %i minutes old.", age//60 ))
        end
      end
      print("Do you want to upload to CTAN? [y/n]" )
      local answer=""
      io.stdout:write("> ")
      io.stdout:flush()
      answer=read()
      if(lower(answer,1,1)=="y") then
        ctanupload=true
      end
    end
    if (ctanupload==true) then
      fp_return = shell(ctan_post .. "upload")
--     this is just html, could save to a file
--     or echo a cleaned up version
      print('Response from CTAN:')
      print(fp_return)
      if match(fp_return,"WARNING") or match(fp_return,"ERROR") then
        exit_status=1
      end
    else
      if (match(fp_return,"WARNING")) then
        print("Warnings from CTAN package validation:" .. fp_return:gsub("%[","\n["):gsub("%]%]","]\n]"))
      else
        print("CTAN validation successful")
      end
    end
  else
    error("Warnings from CTAN package validation:\n" .. fp_return)
  end
  return exit_status
end


function trim_space(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end


function shell(s)
  local h = assert(popen(s, 'r'))
  local t = assert(h:read('*a'))
  local success = h:close()
  if (success) then
   return t
  else
   error("\nError from shell command:\n" .. s .. "\n" .. t .. "\n")
  end
end

function construct_ctan_post(uploadfile,debug)

  -- start building the curl command:
-- commandline  ctan_post = curlexe .. " "
  ctan_post=""

  -- build up the curl command field-by-field:

  --         field                                   max  desc                                 mandatory  multi
  --         ----------------------------------------------------------------------------------------------------
  ctan_field("announcement", uploadconfig.announcement, 8192, "Announcement",                        true,  false )
  ctan_field("author",       uploadconfig.author,        128, "Author name",                         true,  false )
  ctan_field("bugtracker",   uploadconfig.bugtracker,    255, "URL(s) of bug tracker",               false, true  )
  ctan_field("ctanPath",     uploadconfig.ctanPath,      255, "CTAN path",                           true,  false )
  ctan_field("description",  uploadconfig.description,  4096, "Short description of package",        false, false )
  ctan_field("development",  uploadconfig.development,   255, "URL(s) of development channels",      false, true  )
  ctan_field("email",        uploadconfig.email,         255, "Email of uploader",                   true,  false )
  ctan_field("home",         uploadconfig.home,          255, "URL(s) of home page",                 false, true  )
  ctan_field("license",      uploadconfig.license,      2048, "Package license(s)",                  true,  true  )
  ctan_field("note",         uploadconfig.note,         4096, "Internal note to ctan",               false, false )
  ctan_field("pkg",          uploadconfig.pkg,            32, "Package name",                        true,  false )
  ctan_field("repository",   uploadconfig.repository,    255, "URL(s) of source repositories",       false, true  )
  ctan_field("summary",      uploadconfig.summary,       128, "One-line summary of package",         true,  false )
  ctan_field("support",      uploadconfig.support,       255, "URL(s) of support channels",          false, true  )
  ctan_field("topic",        uploadconfig.topic,        1024, "Topic(s)",                            false, true  )
  ctan_field("update",       uploadconfig.update,          8, "Boolean: true=update, false=new pkg", false, false )
  ctan_field("uploader",     uploadconfig.uploader,      255, "Name of uploader",                    true,  false )
  ctan_field("version",      uploadconfig.version,        32, "Package version",                     true,  false )

  ctan_post = ctan_post .. '\nform="file=@' .. tostring(uploadfile) .. ';filename=' .. tostring(uploadfile) .. '"'

  return ctan_post

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
  local fvalueprint = fvalue
  if fvalue == nil then fvalueprint = '??' end
  print('ctan-upload | ' .. fname .. ': ' ..tostring(fvalueprint))
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
      if (fname=="announcement") then
        print("Empty announcement: No ctan announcement will be made")
      else
        error("The field " .. fname .. " must contain " .. desc)
      end
    end
    if (fvalue ~=nil and len(vs) > 0) then
      if (max > 0 and len(vs) > max) then
        error("The field " .. fname .. " is longer than " .. max)
      end
      vs = vs:gsub('\\','\\\\')
      vs = vs:gsub('"','\\"')
      vs = vs:gsub('`','\\`')
      vs = vs:gsub('\n','\\n')
-- for strings on commandline version      ctan_post=ctan_post .. ' --form "' .. fname .. "=" .. vs .. '"'
      ctan_post=ctan_post .. '\nform-string="' .. fname .. '=' .. vs .. '"'
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
    write("> ")
    flush()
    answer_line=read()
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
  until (return_count==3 or answer_line==nil or answer_line=='\004')
  return field
end

function input_single_line_field(name)
  print("Enter " .. name )

  local field=""

  write("> ")
  flush()
  field=read()
  return field
end


-- if filename is non nil and file readable return contents otherwise nil
function file_contents (filename)
  if filename ~= nil then
    local f= open(filename,"r")
    if f==nil then
      return nil
    else
      local s = f:read("*all")
      close(f)
      return s
    end
  else
    return nil
  end
end
