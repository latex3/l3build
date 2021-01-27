--[[

File l3build-global.lua Copyright (C) 2018-2020 The LaTeX3 Project

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

---@module global
---For global data and methods,
---Very first to be loaded
---@usage kpse.set_program_name("kpsewhich"); local l3b = require(kpse.lookup("l3build-global.lua", { path = kpse.lookup("l3build.lua"):match("(.*[/])") }))


-- Local safe guards and shortcuts

local kpse = kpse
local lookup  = kpse.lookup

-- l3build setup and functions

-- next is like `package.path`. Must end with  `;`
local package_path = ""

---`<dir_1>`, `<dir_2>`,... are the paths of supplemental directories where
---`l3build*.lua` files should be looked for.
---Names need not end with a `/`.
---@param dir1 string
---@param dir2 string
---@usage `l3b.package_dir_append(testdir)`
local function package_dir_append(...)
  local arg = table.pack(...)
  for i = 1, arg.n do
    local arg_i = arg[i]
    if #arg_i > 0 then
      package_path = package_path
      .. arg_i .. "/l3build-?.lua;"
      -- .. arg_i .. "/l3build-?/init.lua;" -- for directory packages
    end
  end
end

local loaded = {} -- cache the result of require queries

kpse.set_program_name("kpsewhich")
local build_kpse_path = lookup("l3build.lua"):match("(.*[/])")

---Require `l3build-<key>.lua`.
---Can be used multiple times for the same `<key>` from different files.
---@see package_dir_append to add lookup directories
---@param key string
---@return table or nil
local function l3b_require(key)
  local was = loaded[key]
  if not was then
    local path = lookup("l3build-" .. key .. ".lua", { path = build_kpse_path })
    if not path then
      path = package.searchpath(key, package_path) -- useful for testing
      if not path then
        error("Unsupported l3build package key: " .. key)
      end
    end
    was = { ans = dofile(path) }
    loaded[key] = was
  end
  return was.ans
end

return {
  _TYPE = 'module',
  _NAME = 'global',
  _VERSION = '2021-01-26',
  require = l3b_require,
  package_dir_append = package_dir_append,
}
