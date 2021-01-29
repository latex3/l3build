--[[

File l3build-stdmain.lua Copyright (C) 2018-2020 The LaTeX3 Project

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

local exit   = os.exit
local insert = table.insert

-- List all modules
function listmodules()
  local modules = { }
  local exclmodules = exclmodules or { }
  for entry in lfs.dir(".") do
    if entry ~= "." and entry ~= ".." then
      local attr = lfs.attributes(entry)
      assert(type(attr) == "table")
      if attr.mode == "directory" then
        if not exclmodules[entry] then
          insert(modules, entry)
        end
      end
    end
  end
  return modules
end

target_list = {}

---table definition
---@key func
---@key desc
---@key bundle_func
---@key bundle_target
---@key pre
---@key custom internal usage only, must not be documented publicly
---@table target_definition

---Declare a custom target.
---Exits if the name is already taken,
---if the name is "", if there is no func...
---@param builtin? boolean optional, whether the target is builtin or not, defaults to false
---@param tgt_1 string name of the first target
---@param def_1 table definition of the first target, up to
---@param tgt_n string name of the last target
---@param def_n table definition of the last target
function declare_target(builtin, ...)
  -- The fact that `pre` must return `0` on success was not documented
  -- from the beginning, this really prevented to use `pre`.
  -- Next is some goody just in case the author of `build.lua`
  -- has missed the rule.
  local function ensure_return_0(def, key)
    if type(def[key]) == "function" then
      return function(...)
        local ans = def[key](...)
        if type(ans) ~= "number" then
          ans = 0
        end
        return ans
      end
    elseif def[key] then
      error(key .. " expects a function", 0)
    end
  end
  local feed_target_list -- recursive call => standalone declaration
  feed_target_list = function (tgt_i, def_i, ...) -- take the arguments 2 at a time
    -- this function returns nothing but throws errors
    if not tgt_i then
      return -- arguments exhausted
    elseif #tgt_i == 0 then
      error("Target name must have at least one character", 0)
    elseif target_list[tgt_i] then
      error("Target name " .. tgt_i .. " is already used", 0)
    elseif def_i then
      if type(def_i.func) == "function" then
        local success, msg = pcall(function ()
          target_list[tgt_i] = {
            func          = ensure_return_0(def_i, "func"),
            desc          = def_i.desc,
            bundle_target = def_i.bundle_target,
            bundle_func   = ensure_return_0(def_i, "bundle_func"),
            pre           = ensure_return_0(def_i, "pre"),
            custom        = not builtin,
          }
        end)
        if not success then
          error("Wrong definition for target " .. tgt_i .. "\n" .. msg, 0)
        end
        if not builtin then
          print("New custom target " .. tgt_i)
        elseif options.debug then
          print("New target " .. tgt_i)
        end
        return feed_target_list(...) -- consume the rest
      else
        error("Missing func function in target definition for " .. tgt_i, 0)
      end
    else
      error("Missing target definition for " .. tgt_i, 0)
    end
    -- unreachable
  end
  local success, msg
  if type(builtin) == "boolean" then
    success, msg = pcall(feed_target_list, ...)
  else -- unprovided optional `builtin`, first target name captured instead
    local tgt_1 = builtin
    builtin = false -- targets are created custom by default
    success, msg = pcall(feed_target_list, tgt_1, ...)
  end
  if not success then
    error("!Error: " .. msg, 2)
  end
end

-- next will be reformatted, in the meanwhile is helps diff analyze
declare_target(true, -- these are builtin targets
    -- Some hidden targets (with no desc)
    "bundlecheck",
      {
        func = check,
        pre  = function(names)
            if names then
              print("Bundle checks should not list test names")
              help()
              exit(1)
            end
            return 0
          end
      },
    "bundlectan",
      {
        func = bundlectan
      },
    "bundleunpack",
      {
        func = bundleunpack,
        pre  = function() return(dep_install(unpackdeps)) end
      },
    -- Public targets
    "check",
      {
        bundle_target = true,
        desc = "Run all automated tests",
        func = check,
      },
    "clean",
      {
        bundle_func = bundleclean,
        desc = "Clean out directory tree",
        func = clean
      },
    "ctan",
      {
        bundle_func = ctan,
        desc = "Create CTAN-ready archive",
        func = ctan
      },
    "doc",
      {
        desc = "Typesets all documentation files",
        func = doc
      },
    "install",
      {
        desc = "Installs files into the local texmf tree",
        func = install
      },
    "manifest",
      {
        desc = "Creates a manifest file",
        func = manifest
      },
    "save",
      {
        desc = "Saves test validation log",
        func = save
      },
    "tag",
      {
        bundle_func = function(names)
            local modules = modules or listmodules()
            local errorlevel = call(modules,"tag")
            -- Deal with any files in the bundle dir itself
            if errorlevel == 0 then
              errorlevel = tag(names)
            end
            return errorlevel
          end,
        desc = "Updates release tags in files",
        func = tag,
        pre  = function(names)
           if names and #names > 1 then
             print("Too many tags specified; exactly one required")
             exit(1)
           end
           return 0
         end
      },
    "uninstall",
      {
        desc = "Uninstalls files from the local texmf tree",
        func = uninstall
      },
    "unpack",
      {
        bundle_target = true,
        desc = "Unpacks the source files into the build tree",
        func = unpack
      },
    "upload",
      {
        desc = "Send archive to CTAN for public release",
        func = upload
      }
)

--
-- The overall main function
--

function stdmain(target,names)
  -- Deal with unknown targets up-front
  if not target_list[target] then
    help()
    exit(1)
  end
  local errorlevel = 0
  if module == "" then
    modules = modules or listmodules()
    if target_list[target].bundle_func then
      errorlevel = target_list[target].bundle_func(names)
    else
      -- Detect all of the modules
      if target_list[target].bundle_target then
        target = "bundle" .. target
      end
      errorlevel = call(modules,target)
    end
  else
    if target_list[target].pre then
     errorlevel = target_list[target].pre(names)
     if errorlevel ~= 0 then
       exit(1)
     end
    end
    errorlevel = target_list[target].func(names)
  end
  -- All done, finish up
  if errorlevel ~= 0 then
    exit(1)
  else
    exit(0)
  end
end
