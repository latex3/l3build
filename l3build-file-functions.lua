--[[

File l3build-file-functions.lua Copyright (C) 2018-2024 The LaTeX Project

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
local os_type          = os.type

local luatex_revision  = status.luatex_revision
local luatex_version   = status.luatex_version

local match            = string.match
local sub              = string.sub
local gsub             = string.gsub

local insert           = table.insert

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
os_diffext = getenv("diffext") or ".diff"
os_diffexe = getenv("diffexe") or "diff -c --strip-trailing-cr"
os_grepexe = "grep"
os_newline = "\n"

if os_type == "windows" then
  os_ascii   = "@echo."
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

-- Deal with codepage hell on Windows
local function fixname(f) return f end 
if chgstrcp then
  fixname = chgstrcp.utf8tosyscp
end

-- Deal with the fact that Windows and Unix use different path separators
local function unix_to_win(path)
  return fixname(gsub(path, "/", "\\"))
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
    return escapepath(gsub(gsub(result,"^\\\\%?\\",""), "\\", "/"))
  end
  error(msg)
end

-- TODO: Fix the cross platform problem
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
    return gsub(path,"%[PATH%-SPACE%]","\\ ")
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

function direxists(dir)
  return attributes(dir, "mode") == "directory"
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

-- Copy files 'quietly'
function cp(glob, source, dest)
  local errorlevel
  for _,p in ipairs(tree(source, glob)) do
    -- p_src is a path relative to `source` whereas
    -- p_cwd is the counterpart relative to the current working directory
    if os_type == "windows" then
      if direxists(p.cwd) then
        errorlevel = execute(
          'xcopy /y /e /i "' .. unix_to_win(p.cwd) .. '" '
             .. unix_to_win(dest .. '/' .. escapepath(p.src)) .. ' > nul'
        ) -- execute returns an integer
      else
        errorlevel = execute(
          'xcopy /y "' .. unix_to_win(p.cwd) .. '" '
             .. unix_to_win(dest .. '/') .. ' > nul'
        ) -- execute returns an integer
      end
    else
      -- Ensure we get similar behavior on all platforms
      if not direxists(dirname(dest)) then
        errorlevel = mkdir(dirname(dest))
        if errorlevel ~=0 then return errorlevel end
      end
      errorlevel = execute(
        "cp -RLf '" .. p.cwd .. "' " .. dest
      ) -- execute returns an integer
    end
    if errorlevel ~=0 then
      return errorlevel
    end
  end
  return 0
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
function ordered_filelist(...)
  local files = filelist(...)
  table.sort(files)
  return files
end

---@class tree_entry_t
---@field src string path relative to the source directory
---@field cwd string path counterpart relative to the current working directory

---Does what filelist does, but can also glob subdirectories.
---In the returned table, the keys are paths relative to the given source path,
---the values are their counterparts relative to the current working directory.
---@param src_path string
---@param glob string
---@return table<integer,tree_entry_t>
function tree(src_path, glob)
  local function cropdots(path)
    return path:gsub( "^%./", ""):gsub("/%./", "/")
  end
  src_path = cropdots(src_path)
  glob = cropdots(glob)
  local function always_true()
    return true
  end
  ---@type table<integer,tree_entry_t>
  local result = { {
    src = ".",
    cwd = src_path,
  } }
  for glob_part, sep in glob:gmatch("([^/]+)(/?)/*") do
    local accept = sep == "/" and direxists or always_true
    ---Feeds the given table according to `glob_part`
    ---@param p tree_entry_t path counterpart relative to the current working directory
    ---@param table table
    local function fill(p, table)
      for _,file in ipairs(filelist(p.cwd, glob_part)) do
        if file ~= "." and file ~= ".." then
          local pp = {
            src = p.src .. "/" .. file,
            cwd = p.cwd .. "/" .. file,
          }
          if pp.cwd ~= builddir -- TODO: ensure that `builddir` is properly formatted
          and accept(pp.cwd)
          then
            insert(table, pp)
          end
        end
      end
    end
    local new_result = {}
    if glob_part == "**" then
      local i = 1
      while true do
        local p = result[i]
        i = i + 1
        if not p then
          break
        end
        insert(new_result, p) -- shorter path
        fill(p, result)       -- after longer
      end
    else
      for _,p in ipairs(result) do
        fill(p, new_result)
      end
    end
    result = new_result
  end
  return result
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
  dir = escapepath(dir)
  if os_type == "windows" then
    -- Windows (with the extensions) will automatically make directory trees
    -- but issues a warning if the dir already exists: avoid by including a test
    dir = unix_to_win(dir)
    return execute(
      "if not exist "  .. dir .. "\\nul " .. "mkdir " .. dir
    )
  else
    return execute("mkdir -p " .. dir)
  end
end

-- Rename
function ren(dir, source, dest)
  dir = dir .. "/"
  if os_type == "windows" then
    source = gsub(source, "^%.+/", "")
    dest = gsub(dest, "^%.+/", "")
    return execute("ren " .. unix_to_win(dir) .. source .. " " .. dest)
  else
    return execute("mv " .. dir .. source .. " " .. dir .. dest)
  end
end

-- Remove file(s) based on a glob
function rm(source, glob)
  for _,p in ipairs(tree(source, glob)) do
    rmfile(source,p.src)
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
