--[[

File l3build-file-functions.lua Copyright (C) 2018-2020 The LaTeX Project

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

local pairs            = pairs
local print            = print

local open             = io.open

local attributes       = lfs.attributes
local currentdir       = lfs.currentdir
local chdir            = lfs.chdir
local lfs_dir          = lfs.dir

local execute          = os.execute
local exit             = os.exit
local getenv           = os.getenv
local remove           = os.remove
local os_time          = os.time
local os_type          = os.type

local luatex_revision  = status.luatex_revision
local luatex_version   = status.luatex_version

local match            = string.match
local sub              = string.sub
local gmatch           = string.gmatch
local gsub             = string.gsub

local insert           = table.insert

local byte             = string.byte

-- Convert a file glob into a pattern for use by e.g. string.gub
-- Based on https://github.com/davidm/lua-glob-pattern
-- Simplified substantially: "[...]" syntax not supported as is not
-- required by the file patterns used by the team. Also note style
-- changes to match coding approach in rest of this file.
--
-- License for original globtopattern
--[[

   (c) 2008-2011 David Manura.  Licensed under the same terms as Lua (MIT).

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.
  (end license)

--]]
function glob_to_pattern(glob)

  local pattern = "^" -- pattern being built
  local i = 0 -- index in glob
  local char -- char at index i in glob

  -- escape pattern char
  local function escape(char)
    return match(char, "^%w$") and char or "%" .. char
  end

  -- Convert tokens.
  while true do
    i = i + 1
    char = sub(glob, i, i)
    if char == "" then
      pattern = pattern .. "$"
      break
    elseif char == "?" then
      pattern = pattern .. "."
    elseif char == "*" then
      pattern = pattern .. ".*"
    elseif char == "[" then
      -- Ignored
      print("[...] syntax not supported in globs!")
    elseif char == "\\" then
      i = i + 1
      char = sub(glob, i, i)
      if char == "" then
        pattern = pattern .. "\\$"
        break
      end
      pattern = pattern .. escape(char)
    else
      pattern = pattern .. escape(char)
    end
  end
  return pattern
end

---Sanitize the given path by removing
---what is not necessary.
---@param p string
---@return string
local function sanitize_path(p)
  return p:gsub("//", "/")
          :gsub("^%./", "")
          :gsub("/%./", "/")
          :gsub("[^/]+/%.%./", "")
end

---Boundaries between directories are managed more precisely.
---Named classes are available too.
---This has been seriously revisited, fixed and enhanced.
---@param g string
---@return string
function glob_to_pattern_x(g)
  g =  sanitize_path(g)
  local p = "^"  -- pattern being built
  local i = 0    -- index in g

  -- unescape glob char
  local function unescape(c)
    if c == '\\' then
      i = i + 1; c = g:sub(i,i)
      if c == '' then
        p = '[^]'
        error("Uncomplete escape sequence")
      end
    end
    return true
  end

  -- escape pattern char
  local function escape(c)
    return c:match("^%w$") and c or '%' .. c
  end

  -- Creates a character range but excludes "/".
  local function range(left, right)
    local l = byte(left)
    local r = byte(right)
    if l > r then return "" end
    if l == 0x2F then l = 0x30; left  = "0" end -- shift right
    if r == 0x2F then r = 0x2E; right = "." end -- shift left
    if l > r then return "" end -- it was a /-/ range
    if l > 0x2F or r < 0x2F then
      return escape(left) .. "-" .. escape(right)
    end
    -- l < 0x2F < r
    local ans = escape(left)
    if l < 0x2E then
      ans = ans .. "-.0"
    end
    if r > 0x30 then
      ans = ans .. "-" .. escape(right)
    end
    return ans
  end
  -- terminates the scanning of a character set
  local function charset_end(c)
    while 1 do
      if c == '' then
        p = '[^]'
        error('No void class')
      elseif c == '[' then
        p = p .. '%['
      elseif c == ']' then
        p = p .. ']'
        break
      else
        unescape(c)
        local c1 = c
        i = i + 1; c = g:sub(i,i)
        if c == '' then
          p = '[^]'
          error('Missing "]"')
        elseif c == '-' then
          i = i + 1; c = g:sub(i,i)
          if c == '' then
            p = '[^]'
            error('Missing "]"')
          elseif c == ']' then
            p = p .. escape(c1) .. '%-]'
            break
          else
            unescape(c)
            p = p .. range(c1, c)
          end
        elseif c == ']' then
          p = p .. escape(c1) .. ']'
          break
        else
          p = p .. escape(c1)
          i = i - 1 -- put back
        end
      end
      i = i + 1; c = g:sub(i,i)
    end
    return true
  end
  -- Convert tokens in charset.
  local function charset(c)
    local l = #p
    if c == '' then
      p = '[^]'
      error('Missing closing "]"')
    end
    if c == '-' then
      i = i + 1; c = g:sub(i,i)
      if c == '-' then -- this might be a range
        i = i + 1; c = g:sub(i,i)
        if c == "]" then
          p = p .. "%-"
          return true
        end
        p = p .. "[" .. range("-", c)
        i = i + 1; c = g:sub(i,i)
      else
        p = p .. '%-'
        i = i + 1; c = g:sub(i,i)
      end
    elseif c == ']' then
      p = p .. '[%]'
      i = i + 1; c = g:sub(i,i)
    elseif c == '^' or c == '!' then
      i = i + 1; c = g:sub(i,i)
      if c == ']' then
        p = p .. '[^%]'
        i = i + 1; c = g:sub(i,i)
      else
        p = p .. '[^'
      end
    else
      p = p .. '['
    end
    charset_end(c)
    if #p == l + 2 then -- "[z-a]"
      p = p .. "\8" .. "^]"
    end
  end

  local function named_class()
    -- unsupported: [:blank:] and [:graph:]
    -- i points after "[:"
    local name = g:match("^([a-z]+):%]", i)
    if not name then
      error("Missing class name")
    end
    local map = {
      alpha = "a", -- letters
      cntrl = "c", -- control characters
      digit = "d", -- digits
      print = "g", -- printable characters except space.
      lower = "l", -- lowercase letters
      punct = "p", -- punctuation characters
      space = "s", -- space characters
      upper = "u", -- uppercase letters
      alnum = "w", -- alphanumeric characters
      xdigit = "x", -- hexadecimal digits
    }
    local q = map[name]
    if not q then
      error("unknown class name")
    end
    p = p .. "%" .. q
    i = i + #name + 1
  end
  -- Convert tokens.
  local ok, msg = pcall(function ()
    while 1 do
      i = i + 1; local c = g:sub(i,i)
      ::if_c::
      if c == '' then
        p = p .. '$'
        break
      elseif c == '?' then
        p = p .. '[^/]'
      elseif c == '*' then
        i = i + 1; c = g:sub(i,i)
        if c == '*' then
          p = p .. '.*'
        else
          p = p .. '[^/]*'
          goto if_c
        end
      elseif c == '[' then
        i = i + 1; c = g:sub(i,i)
        if c == ":" then
          i = i + 1; c = g:sub(i,i)
          if c == "]" then
            p = p .. ":"
          else
            named_class(c)
          end
        else
          charset(c)
        end
      elseif c == '\\' then
        i = i + 1; c = g:sub(i,i)
        if c == '' then
          p = p .. '\\$'
          break
        end
        p = p .. escape(c)
      else
        p = p .. escape(c)
      end
    end
  end)
  if ok then
    return p
  end
  error("Error \"" .. g .. "\": " .. msg)
end

-- Detect the operating system in use
-- Support items are defined here for cases where a single string can cover
-- both Windows and Unix cases: more complex situations are handled inside
-- the support functions
os_concat  = ";"
os_null    = "/dev/null"
os_pathsep = ":"
os_setenv  = "export"
os_yes     = "printf 'y\\n%.0s' {1..300}"

os_ascii   = "echo \"\""
os_cmpexe  = getenv("cmpexe") or "cmp"
os_cmpext  = getenv("cmpext") or ".cmp"
os_diffext = getenv("diffext") or ".diff"
os_diffexe = getenv("diffexe") or "diff -c --strip-trailing-cr"
os_grepexe = "grep"
os_newline = "\n"

if os_type == "windows" then
  os_ascii   = "@echo."
  os_cmpexe  = getenv("cmpexe") or "fc /b"
  os_cmpext  = getenv("cmpext") or ".cmp"
  os_concat  = "&"
  os_diffext = getenv("diffext") or ".fc"
  os_diffexe = getenv("diffexe") or "fc /n"
  os_grepexe = "findstr /r"
  os_newline = "\n"
  if tonumber(luatex_version) < 100 or
     (tonumber(luatex_version) == 100
       and tonumber(luatex_revision) < 4) then
    os_newline = "\r\n"
  end
  os_null    = "nul"
  os_pathsep = ";"
  os_setenv  = "set"
  os_yes     = "for /l %I in (1,1,300) do @echo y"
end

-- Deal with the fact that Windows and Unix use different path separators
local function unix_to_win(path)
  return gsub(path, "/", "\\")
end

function normalize_path(path)
  if os_type == "windows" then
    return unix_to_win(path)
  end
  return path
end

-- Return an absolute path from a relative one
-- Due to chdir, path must exist and be accessible.
function abspath(path)
  local oldpwd = currentdir()
  local ok, msg = chdir(path)
  if ok then
    local result = currentdir()
    chdir(oldpwd)
    return escapepath(gsub(result, "\\", "/"))
  end
  error(msg)
end

function escapepath(path)
  if os_type == "windows" then
    local path,count = gsub(path,'"','')
    if count % 2 ~= 0 then
      print("Unbalanced quotes in path")
      exit(0)
    else
      if match(path," ") then
        return '"' .. path .. '"'
      end
      return path
    end
  else
    path = gsub(path,"\\ ","[PATH-SPACE]")
    path = gsub(path," ","\\ ")
    return gsub(path,"%[PATH-SPACE%]","\\ ")
  end
end

-- For cleaning out a directory, which also ensures that it exists
function cleandir(dir)
  local errorlevel = mkdir(dir)
  if errorlevel ~= 0 then
    return errorlevel
  end
  return rm(dir, "**")
end

-- Copy files 'quietly'
function cp(glob, source, dest)
  local errorlevel
  for i,_ in pairs(tree(source, glob)) do
    local source = source .. "/" .. i
    if os_type == "windows" then
      if attributes(source)["mode"] == "directory" then
        errorlevel = execute(
          'xcopy /y /e /i "' .. unix_to_win(source) .. '" "'
             .. unix_to_win(dest .. '/' .. i) .. '" > nul'
        )
      else
        errorlevel = execute(
          'xcopy /y "' .. unix_to_win(source) .. '" "'
             .. unix_to_win(dest .. '/') .. '" > nul'
        )
      end
    else
      errorlevel = execute("cp -RLf '" .. source .. "' '" .. dest .. "'")
    end
    if errorlevel ~=0 then
      return errorlevel
    end
  end
  return 0
end

-- OS-dependent test for a directory
function direxists(dir)
  local errorlevel
  if os_type == "windows" then
    errorlevel =
      execute("if not exist \"" .. unix_to_win(dir) .. "\" exit 1")
  else
    errorlevel = execute("[ -d '" .. dir .. "' ]")
  end
  if errorlevel ~= 0 then
    return false
  end
  return true
end

function fileexists(file)
  local f = open(file, "r")
  if f ~= nil then
    f:close()
    return true
  else
    return false -- also file exits and is not readable
  end
end

-- Generate a table containing all file names of the given glob or all files
-- if absent
function filelist(path, glob)
  local files = { }
  local pattern
  if glob then
    pattern = glob_to_pattern(glob)
  end
  if direxists(path) then
    for entry in lfs_dir(path) do
      if pattern then
        if match(entry, pattern) then
          insert(files, entry)
        end
      else
        if entry ~= "." and entry ~= ".." then
          insert(files, entry)
        end
      end
    end
  end
  return files
end

-- Does what filelist does, but can also glob subdirectories. In the returned
-- table, the keys are paths relative to the given starting path, the values
-- are their counterparts relative to the current working directory.
function tree(path, glob)
  local function cropdots(path)
    return gsub(gsub(path, "^%./", ""), "/%./", "/")
  end
  local function always_true()
    return true
  end
  local function is_dir(file)
    return attributes(file)["mode"] == "directory"
  end
  local dirs = {["."] = cropdots(path)}
  for pattern, criterion in gmatch(cropdots(glob), "([^/]+)(/?)") do
    local criterion = criterion == "/" and is_dir or always_true
    function fill(path, dir, table)
      for _, file in ipairs(filelist(dir, pattern)) do
        local fullpath = path .. "/" .. file
        if file ~= "." and file ~= ".." and
          fullpath ~= builddir
        then
          local fulldir = dir .. "/" .. file
          if criterion(fulldir) then
            table[fullpath] = fulldir
          end
        end
      end
    end
    local newdirs = {}
    if pattern == "**" then
      while true do
        path, dir = next(dirs)
        if not path then
          break
        end
        dirs[path] = nil
        newdirs[path] = dir
        fill(path, dir, dirs)
      end
    else
      for path, dir in pairs(dirs) do
        fill(path, dir, newdirs)
      end
    end
    dirs = newdirs
  end
  return dirs
end

function remove_duplicates(a)
  -- Return array with duplicate entries removed from input array `a`.

  local uniq = {}
  local hash = {}

  for _,v in ipairs(a) do
    if (not hash[v]) then
      hash[v] = true
      uniq[#uniq+1] = v
    end
  end

  return uniq
end

function mkdir(dir)
  if os_type == "windows" then
    -- Windows (with the extensions) will automatically make directory trees
    -- but issues a warning if the dir already exists: avoid by including a test
    local dir = unix_to_win(dir)
    return execute(
      "if not exist "  .. dir .. "\\nul " .. "mkdir " .. dir
    )
  else
    return execute("mkdir -p " .. dir)
  end
end

-- Rename
function ren(dir, source, dest)
  local dir = dir .. "/"
  if os_type == "windows" then
    local source = gsub(source, "^%.+/", "")
    local dest = gsub(dest, "^%.+/", "")
    return execute("ren " .. unix_to_win(dir) .. source .. " " .. dest)
  else
    return execute("mv " .. dir .. source .. " " .. dir .. dest)
  end
end

-- Remove file(s) based on a glob
function rm(source, glob)
  for i,_ in pairs(tree(source, glob)) do
    rmfile(source,i)
  end
  -- os.remove doesn't give a sensible errorlevel
  return 0
end

-- Remove file
function rmfile(source, file)
  remove(source .. "/" .. file)
  -- os.remove doesn't give a sensible errorlevel
  return 0
end

-- Remove a directory tree
function rmdir(dir)
  -- First, make sure it exists to avoid any errors
  mkdir(dir)
  if os_type == "windows" then
    return execute("rmdir /s /q " .. unix_to_win(dir))
  else
    return execute("rm -r " .. dir)
  end
end

-- Run a command in a given directory
function run(dir, cmd)
  return execute("cd " .. dir .. os_concat .. cmd)
end

-- Split a path into file and directory component
function splitpath(file)
  local path, name = match(file, "^(.*)/([^/]*)$")
  if path then
    return path, name
  else
    return ".", file
  end
end

-- Arguably clearer names
function basename(file)
  return(select(2, splitpath(file)))
end

function dirname(file)
  return(select(1, splitpath(file)))
end

-- Strip the extension from a file name (if present)
function jobname(file)
  local name = match(basename(file), "^(.*)%.")
  return name or file
end

-- Look for files, directory by directory, and return the first existing
function locate(dirs, names)
  for _,i in ipairs(dirs) do
    for _,j in ipairs(names) do
      local path = i .. "/" .. j
      if fileexists(path) then
        return path
      end
    end
  end
end
