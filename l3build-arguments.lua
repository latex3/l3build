--[[

File l3build-arguments.lua Copyright (C) 2018-2025 The LaTeX Project

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

local exit             = os.exit
local stderr           = io.stderr

local find             = string.find
local gmatch           = string.gmatch
local match            = string.match
local sub              = string.sub

local insert           = table.insert

-- Parse command line options

option_list =
  {
    config =
      {
        desc  = "Sets the config(s) used for running tests",
        short = "c",
        type  = "table"
      },
    date =
      {
        desc  = "Sets the date to insert into sources",
        short = "d",
        type  = "string"
      },
    debug =
      {
        desc = "Runs target in debug mode",
        type = "boolean"
      },
    dev =
      {
        desc = "Use the development LaTeX format",
        type = "boolean"
      },
    dirty =
      {
        desc = "Skips cleaning up the test area",
        type = "boolean"
      },
    ["dry-run"] =
      {
        desc = "Dry run for install or upload",
        type = "boolean"
      },
    email =
      {
        desc = "Email address of CTAN uploader",
        type = "string"
      },
    engine =
      {
        desc  = "Sets the engine(s) to use for running test",
        short = "e",
        type  = "table"
      },
    epoch =
      {
        desc  = "Sets the epoch for tests and typesetting",
        type  = "string"
      },
    file =
      {
        desc  = "Takes the upload announcement from the given file",
        short = "F",
        type  = "string"
      },
    first =
      {
        desc  = "Name of first test to run",
        type  = "string"
      },
    full =
      {
        desc = "Installs all files",
        type = "boolean"
      },
    ["halt-on-error"] =
      {
        desc  = "Stops running tests after the first failure",
        short = "H",
        type  = "boolean"
      },
    help =
      {
        desc  = "Prints this message and exits",
        short = "h",
        type  = "boolean"
      },
    last =
      {
        desc  = "Name of last test to run",
        type  = "string"
      },
    message =
      {
        desc  = "Text for upload announcement message",
        short = "m",
        type  = "string"
      },
    quiet =
      {
        desc  = "Suppresses TeX output when unpacking",
        short = "q",
        type  = "boolean"
      },
    rerun =
      {
        desc  = "Skips setup: simply reruns tests",
        type  = "boolean"
      },
    ["show-log-on-error"] =
      {
        desc  = "Shows the full log of the failure with 'halt-on-error'",
        type  = "boolean"
      },
    ["show-saves"] =
      {
        desc  = "Shows the invocation to update failing .tlg files",
        short = "S",
        type  = "boolean"
      },
    shuffle =
      {
        desc  = "Shuffles order of tests",
        type  = "boolean"
      },
    stdengine =
      {
        desc  = "Run tests with the std engine (config dependent)",
        short = "s",
        type  = "boolean"
      },
    texmfhome =
      {
        desc = "Location of user texmf tree",
        type = "string"
      },
    version =
      {
        desc = "Prints version information and exits",
        type = "boolean"
      }
  }

-- This is done as a function (rather than do ... end) as it allows early
-- termination (break)
local function argparse()
  local result = { }
  local names  = { }
  local long_options =  { }
  local short_options = { }
  -- Turn long/short options into two lookup tables
  for k,v in pairs(option_list) do
    if v["short"] then
      short_options[v["short"]] = k
    end
    long_options[k] = k
  end
  local arg = arg
  -- arg[1] is a special case: must be a command or "-h"/"--help"
  -- Deal with this by assuming help and storing only apparently-valid
  -- input
  local a = arg[1]
  result["target"] = "help"
  if a then
    -- No options are allowed in position 1, so filter those out
    if a == "--version" then
      result["target"] = "version"
    elseif not match(a, "^%-") then
      result["target"] = a
    end
  end
  -- Stop here if help or version is required
  if result["target"] == "help" or result["target"] == "version" then
    return result
  end
  -- An auxiliary to grab all file names into a table
  local function remainder(num)
    local names = { }
    for i = num, #arg do
      insert(names, arg[i])
    end
    return names
  end
  -- Examine all other arguments
  -- Use a while loop rather than for as this makes it easier
  -- to grab arg for optionals where appropriate
  local i = 2
  while i <= #arg do
    local a = arg[i]
    -- Terminate search for options
    if a == "--" then
      names = remainder(i + 1)
      break
    end
    -- Look for optionals
    local opt
    local optarg
    local opts
    -- Look for and option and get it into a variable
    if match(a, "^%-") then
      if match(a, "^%-%-") then
        opts = long_options
        local pos = find(a, "=", 1, true)
        if pos then
          opt    = sub(a, 3, pos - 1)
          optarg = sub(a, pos + 1)
        else
          opt = sub(a, 3)
        end
      else
        opts = short_options
        opt  = sub(a, 2, 2)
        -- Only set optarg if it is there
        if #a > 2 then
          optarg = sub(a, 3)
        end
      end
      -- Now check that the option is valid and sort out the argument
      -- if required
      local optname = opts[opt]
      if optname then
        -- Tidy up arguments
        if option_list[optname]["type"] == "boolean" then
          if optarg then
            local opt = "-" .. (match(a, "^%-%-") and "-" or "") .. opt
            stderr:write("Value not allowed for option " .. opt .."\n")
            return { target = "help" }
          end
        else
          if not optarg then
            optarg = arg[i + 1]
            if not optarg then
              stderr:write("Missing value for option " .. a .."\n")
              return { target = "help" }
            end
            i = i + 1
          end
        end
      else
        stderr:write("Unknown option " .. a .."\n")
        return { target = "help" }
      end
      -- Store the result
      if optarg then
        if option_list[optname]["type"] == "string" then
          result[optname] = optarg
        else
          local opts = result[optname] or { }
          for hit in gmatch(optarg, "([^,]+)") do
            insert(opts, hit)
          end
          result[optname] = opts
        end
      else
        result[optname] = true
      end
      i = i + 1
    end
    if not opt then
      names = remainder(i)
      break
    end
  end
  if next(names) then
    result["names"] = names
  end
  return result
end

options = argparse()

-- Sanity check
function check_engines(config)
  if options["engine"] then
    -- Make a lookup table
    local t = { }
    for _, engine in pairs(checkengines) do
      t[engine] = true
    end
    checkengines = {}
    for _,engine in ipairs(options["engine"]) do
      if t[engine] then
          insert(checkengines,engine)
      else
        print("Skipping unknown engine " .. engine)
      end
    end
  end
  if not next(checkengines) then
    print("No applicable engine requested, config ignored")
    exit(0)
  end
end
