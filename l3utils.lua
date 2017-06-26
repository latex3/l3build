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

--- Ensures the variable holds any value or falls back to a default value.
-- This function might sound like a bit verbose, but it is added as a means to
-- add a semantic layer to the existing code. The name implies the function
-- behaviour, thus helping comprehension.
-- @param value the variable value to be checked.
-- @param default the default value to be returned in case the variable does
-- not hold any value.
-- @return the existing value variable if it holds any value or a predefined
-- value.
function l3utils.ensure(value, default)
  return value or default
end

--- Checks if the script is running on a Windows machine.
-- This function checks if Windows is the underlying operating system
-- by inspecting the path separator. The occurrence of '\' indicates a
-- Windows machine.
-- @return a logic value indicating whether the script is running on a
-- Windows machine.
function l3utils.windows()
  return package.config:sub(1, 1) == '\\'
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
  force = l3utils.ensure(force, false)
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
  return ((not l3utils.windows() or force) and '\027[00;' ..
  l3utils.ensure(colours[key], colours['reset']) .. 'm') or ''
end

--- Returns a string enclosed in a colour scheme.
-- This function returns a string enclosed in a colour scheme based on the
-- provided key. If the script is running on Windows, there will be no coloured
-- output, unless an optional flag is set to override this behaviour.
-- @param key the colour key.
-- @param text the string to be enclosed.
-- @param force a logic value to force the colour scheme regardless of the
-- underlying operating system.
-- @return the string enclosed in a colour scheme if the operating system is
-- not Windows, or a non-coloured output otherwise (can be overriden).
function l3utils.coloured(key, text, force)
  force = l3utils.ensure(force, false)
  return l3utils.colour(key, force) ..
    text .. l3utils.colour('reset', force)
end

--- Gets the linebreak symbol.
-- This function gets the linebreak symbol based on the underlying
-- operating system. It was written to be as much platform-independent as
-- possible.
-- @return the linebreak symbol (potentially '\n').
function l3utils.linebreak()
  return package.config:sub(2, 2)
end

--- Wraps a string into a sequence of lines according to a specified
--- width.
-- This function takes a string and splits it into a sequence of lines,
-- separated by the default linebreak symbol (potentially '\n'). Lines
-- are broken at spaces. The logic behind this function aims at handling
-- coloured sentences as well, but it was not tested enough. Note that
-- Lua has some issues handling Unicode strings, so this function is
-- still marked as experimental.
-- @param text the text to be wrapped, may include coloured parts.
-- @param width a nonzero, positive integer representing the number of
-- colums to be displayed (in general, a sensible value would be lower
-- than 80 columns).
-- @return the wrapped string.
function l3utils.wrap(text, width)
  local wrapped, colour, lb = '', '', l3utils.linebreak()
  local checkpoint, counter = 1, 1
  local closed, reset = true, '\027[00;00m'

  local peek = function(t)
    local _, b, c = string.find(t, '^(\027%[00;%d%dm)')
    b = l3utils.ensure(b, 0)
    return string.sub(t, b + 1, b + 1), c, string.sub(t, b + 2)
  end

  while #text ~= 0 do

    local a, b, c = peek(text)
    text = c

    if b then
      colour = b
      closed = not closed
    end

    wrapped = wrapped .. l3utils.ensure(b, '') .. a

    if string.byte(a) ~= 195 then
      counter = counter + 1
    end

    if a == ' ' then
      checkpoint = #wrapped
    end

    if counter >= width then
      wrapped = string.sub(wrapped, 1, checkpoint) ..
      ((not closed and reset) or '') .. lb ..
      ((not closed and colour) or '') ..
      string.sub(wrapped, checkpoint + 1)
      counter = 0
    end

  end

  return wrapped
end

