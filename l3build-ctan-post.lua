
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

-- The input form could be used to constrict a post body but
-- luasec is not included in texlua.

-- Instead an external program is used to post.
-- As Windows (since April 2018) includes curl now default to curl.

-- A global variable controls the backend to use.
-- ctan_post_command=="curl"
-- ctan_post_command=="ctan-o-mat"
--
-- ctan-o-mat inroduces a dependency on perl but it is installed with texlive
-- in the default path and is maintained by Gerd Neugebauer of the CTAN team.
--
-- The ctan-o-mat configuration is written out as ctan-upload.txt
-- in the current version it is a fixed name and not deleted after use,
-- as a debugging aid.


-- the main interface is
-- ctan_upload (c,upload)
-- with a configuration table c and optional upload parameter
-- if upload is omitted or nil or false, onloy validation is attempted
-- if upload is true the ctan upload URL will be used  after validation
-- if upload is anything else, the user will beprompted whether to upload.

ctan_post_command="curl"
curl_debug=false -- posting is disabled while testing

function ctan_upload (c,upload)

  if ctan_post_command=="ctan-o-mat" then
    c.cfg = io.open("ctan-upload.txt","w")
  else
    if ctan_post_command=="curl" then
      c.cfg="curl "
    else
      error("no https post command set")
    end
  end


  --        cfg field max desc                   mandatory multi
  --        ----------------------------------------------------
  ctan_field(c,"pkg",32,"the package name",       true,false)
  ctan_field(c,"version",32,"the package version",true,false)
  ctan_field(c,"author",128,"the author name",    true,false)
  ctan_field(c,"email",255,"the email of uploader",true,false)
  ctan_field(c,"uploader",255,"the name of uploader",true,false)
  ctan_field(c,"ctanPath",255,"the CTAN path",    false,false)
  ctan_field(c,"license",2048,"Package License",  true,true)
  ctan_field(c,"home",255,"URL of home page",     false,false)
  ctan_field(c,"bugtracker",255,"URL of bug tracker",false,false)
  ctan_field(c,"support",255,"URL of support channels",false,true)
  ctan_field(c,"repository",255,"URL of source repositories",false,true)
  ctan_field(c,"development",255,"URL of development channels",false,true)
  ctan_field(c,"update",8,",true for an update false otherwise",false,false)
  ctan_field(c,"topic",1024,"topic",              false,true)
  ctan_field(c,"announcement",8192,"announcement",false,false)
  ctan_field(c,"summary",128,"summary",           true,false) -- ctan-o-mat doc says optional
  ctan_field(c,"description",4096,"description",  false,false)
  ctan_field(c,"note",4096,"internal note to ctan",false,false)

  if ctan_post_command=="ctan-o-mat" then
    ctan_field(c,"file",4096,"zip file to upload",  true,false)
    io.close(c.cfg)
  else
    if ctan_post_command=="curl" then
      c.cfg=c.cfg .. " --form 'file=@" .. tostring(c.file) .. ";filename=" .. tostring(c.file) .. "'"
      c.cfg=c.cfg ..  " https://ctan.org/submit/"
    else
      error("no https post command set")
    end
  end


  -- avoid lower level error from post command if zip file missing
  local zip=io.open(trim_space(tostring(c.file)),"r")
  if zip~=nil then
    io.close(zip)
  else
    error("missing zip file " .. tostring(c.file))
  end

  -- call post command to validate the upload at CTAN's validate URL
  local exit_status=0
  local fp_return=""
  if ctan_post_command=="ctan-o-mat" then
    exit_status=os.execute("ctan-o-mat --validate ctan-upload.txt")
  else
    if ctan_post_command=="curl" then
--    use popen not execute so get the return body local exit_status=os.execute(c.cfg .. "validate")
      if(curl_debug==false) then
        local fp = assert(io.popen(c.cfg .. "validate", 'r'))
        fp_return = assert(fp:read('*a'))
        fp:close()
      else
       fp_return="WARNING: curl_debug==true: posting disabled disabled"
       print(c.cfg)
      end
      if string.match(fp_return,"WARNING") or string.match(fp_return,"ERROR") then
       exit_status=1
      end
    else
      error("no https post command set")
    end
  end

  -- if upload requested and validation succeeded repost to the upload URL
  if (exit_status==0 or exit_status==nil) then
    if(upload ~=nil and upload ~=false and upload ~= true) then
      print("Validation successful, do you want to upload to CTAN?" )
      local answer=""
      io.write("> ")
      io.flush()
      answer=io.read()
      if(string.lower(answer,1,1)=="y") then
        upload=true
      end
    end
    if(upload==true) then
      if ctan_post_command=="ctan-o-mat" then
        exit_status=os.execute("ctan-o-mat ctan-upload.txt")
      else
        if ctan_post_command=="curl" then
          local fp = assert(io.popen(c.cfg .. "upload", 'r'))
          fp_return = assert(fp:read('*a'))
          fp:close()

--         this is just html, could save to a file
--         or echo a cleaned up version
          print('Response from CTAN:')
          print(fp_return)
          if string.match(fp_return,"WARNING") or string.match(fp_return,"ERROR") then
            exit_status=1
          end
        else
          error("no https post command set")
        end
      end
    else
      print("CTAN validation successful")
    end
  else
    error("Warnings from CTAN package validation:\n" .. fp_return)
  end
end

function trim_space(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function ctan_field(c,f,max,desc,mandatory,multi)
  if(type(c) ~= "table") then
    error("The configuration argument must be a Lua table")
  end
  if(type(c[f])=="table" and multi==true) then
    for i, v in pairs(c[f]) do
      ctan_single_field(c,f,v,max,desc,mandatory and i==1)
    end
  else
    ctan_single_field(c,f,c[f],max,desc,mandatory)
  end
end

-- for URL %-encoding but not used presently
local char_to_hex = function(c)
  return string.format("%%%02X", string.byte(c))
end

function ctan_single_field(c,f,v,max,desc,mandatory)
  if(v==nil or type(v)~="table") then
    local vs=trim_space(tostring(v))
    if (mandatory==true and (v == nil or vs=="")) then
      error("The field " .. f .. " must contain " .. desc)
    end
    if(v ~=nil and string.len(vs) > 0) then
      if (max > 0 and string.len(vs) > max) then
        error("The field " .. f .. " is longer than " .. max)
      end
      if ctan_post_command=="ctan-o-mat" then
        c.cfg:write("\n\\begin{" .. f .. "}\n" .. vs .. "\n\\end{" .. f .. "}\n")
      else
        if ctan_post_command=="curl" then
-- curl supports using \" in " delimited strings but not \' in ' delimited omes
--          c.cfg=c.cfg .." --form " .. f .. "='" .. vs:gsub("([^%w])",char_to_hex) .. "'"
          c.cfg=c.cfg .." --form " .. f .. '="' .. vs:gsub('"','\\"') .. '"'
        else
          error("no https post command set")
	end
      end
    end
  else
    error("The value of the field '" .. f .."' must be a scalar not a table")
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

