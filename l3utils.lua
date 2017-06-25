--[[

File l3utils.lua Copyright (C) 2014-2017 The LaTeX3 Project

It may be distributed and/or modified under the conditions of the
LaTeX Project Public License (LPPL), either version 1.3c of this
license or (at your option) any later version.  The latest version
of this license is in the file

   http://www.latex-project.org/lppl.txt

This file is part of the "l3build bundle" (The Work in LPPL)
and all files in that bundle must be distributed together.

-----------------------------------------------------------------------

The development version of the bundle can be found at

   https://github.com/latex3/latex3

for those people who are interested.

--]]

-- the LaTeX3 utils namespace
local l3utils = {}

--- Checks if the script is running on a Windows machine.
-- This function checks if Windows is the underlying operating system
-- by inspecting the path separator. The occurrence of '\' indicates a
-- Windows machine.
-- @return a logic value indicating whether the script is running on a
-- Windows machine.
function l3utils.windows()
  return package.config:sub(1,1) == '\\'
end

--- Calculates the colour scheme for Unix-like terminals.
-- This function calculates the colour scheme based on the provided
-- key or falls back to a reset command if the colour is not mapped.
-- By default, the function does nothing if the script is running on
-- Windows, but this behaviour can be overriden if a second parameter is
-- provided.
-- @param key the colour name, currently set to the default one used
-- in the user terminal, black, red, green, yellow, blue, magenta, cyan,
-- light grey, dark grey, light red, light green, light yellow, light
-- blue, light magenta, light cyan, and white. Additionally, there is a
-- reset key to restore the defaults.
-- @param force a logic flag indicating if the colour scheme should be
-- returned regardless of the underlying operational system.
-- @return a string containing the colour scheme for Unix-like
-- terminals, or an empty string in case of Windows (can be overriden).
function l3utils.colour(key, force)
  force = force or false
  local colours = {
    default      = '39',
    black        = '30',
    red          = '31',
    green        = '32',
    yellow       = '33',
    blue         = '34',
    magenta      = '35',
    cyan         = '36',
    lightgrey    = '37',
    darkgrey     = '90',
    lightred     = '91',
    lightgreen   = '92',
    lightyellow  = '93',
    lightblue    = '94',
    lightmagenta = '95',
    lightcyan    = '96',
    white        = '97',
    reset        = '00'
  }
  return ((not l3utils.windows() or force) and
    '\027[00;' .. (colours[key] or
    colours['reset']) .. 'm') or ''
end

--- Returns a string enclosed in a colour scheme.
-- This function returns a string enclosed in a colour scheme based on the
-- provided key. If the script is running on Windows, there will be no coloured
-- output, unless an optional flag is set to override this behaviour.
-- @param key the colour key.
-- @param text the string to be enclosed.
-- @param force a logic value to force the colour scheme regardless of the
-- underlying operating system.
function l3utils.coloured(key, text, force)
  force = force or false
  return l3utils.colour(key, force) ..
    text .. l3utils.colour('reset', force)
end

