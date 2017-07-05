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

--[[

Documentation can be generated with:
$ ldoc -f markdown l3utils.lua

--]]

--- Provides utility functions for the `l3build` testing and building
--- system.
-- The `l3utils` module provides utility functions for `l3build`. Note
-- that functions are available through a namespace.

-- the LaTeX3 utils namespace
local l3utils = {}

--- Ensures the variable holds any value or falls back to a default value.
-- This function might sound like a bit verbose, but it is added as a means to
-- add a semantic layer to the existing code. The name implies the function
-- behaviour, thus helping comprehension.
-- @param value the variable value to be checked.
-- @param default the default value to be returned in case the variable does
-- not hold any value.
-- @return The existing value variable if it holds any value or a predefined
-- value.
function l3utils.ensure(value, default)
  return value or default
end

--- Checks if the script is running on a Windows machine.
-- This function checks if Windows is the underlying operating system
-- by inspecting the path separator. The occurrence of `\` indicates a
-- Windows machine.
-- @return A logic value indicating whether the script is running on a
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
-- @return A string containing the colour scheme for Unix-like
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
-- @return The string enclosed in a colour scheme if the operating system is
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
-- @return The linebreak symbol (potentially `\n`).
function l3utils.linebreak()
  return package.config:sub(2, 2)
end

--- Wraps a string into a sequence of lines according to a specified
--- width.
-- This function takes a string and splits it into a sequence of lines,
-- separated by the default linebreak symbol (potentially `\n`). Lines
-- are broken at spaces. The logic behind this function aims at handling
-- coloured sentences as well, but it was not tested enough. Note that
-- Lua has some issues handling Unicode strings, so this function is
-- still marked as experimental.
-- @param text the text to be wrapped, may include coloured parts.
-- @param width a nonzero, positive integer representing the number of
-- colums to be displayed (in general, a sensible value would be lower
-- than 80 columns).
-- @return The wrapped string.
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

--- Resolves an option key based on the CLI configuration table to a
--- normalized reference.
-- This function takes an option key in its short or long form and
-- returns the long form. If the option key does not exist in the CLI
-- configuration table, a nil value is returned.
-- @param key The option key without the dash prefix.
-- @param configuration The CLI configuration table.
-- @return The long form of the provided option key as a normalized
-- reference, or a nil value if the key does not exist in the CLI
-- configuration table.
function l3utils.keyresolve(key, configuration)
  for _, v in ipairs(configuration) do
    if v['short'] == key or v['long'] == key then
      return v['long']
    end
  end
  return nil
end

--- Checks if the provided option key has arguments and, if any, the
--- minimum and maximum values defined in the CLI configuration table.
-- This function takes an option key and checks if such option is
-- expected to take arguments. If so, the minimum an maximum values
-- are returned, or a nil value otherwise. Values are set in the CLI
-- configuration table.
-- @param key The option key without the dash prefix.
-- @param configuration The CLI configuration table.
-- @return The minimum an maximum values in case the option is expected
-- to take arguments, or a nil value otherwise, based on the CLI
-- configuration table.
function l3utils.parametercheck(key, configuration)
  for _, v in ipairs(configuration) do
    if v['long'] == key then
      if v['parameters'] then
        return l3utils.ensure(v['parameters']['min'], 1),
               l3utils.ensure(v['parameters']['max'], 1)
      else
        return nil
      end
    end
  end
end

--- Checks if the option key can take more arguments, if any.
-- This function takes an option key, the CLI configuration table and
-- the current list of elements, and checks if the option can take more
-- elements. If so, the key is kept unchanged and it is returned as is,
-- or an `unpaired` value is returned.
-- @param key The option key.
-- @param configuration The CLI configuration table.
-- @param list The current list of elements referring to the provided
-- option key.
-- @return The unchanged key if the current list of elements can take
-- another element, or the `unpaired` key, indicating that the exceeding
-- arguments must be in the generic list.
function l3utils.keycheck(key, configuration, list)
  if key == 'unpaired' then
    return key
  else
      local min, max = l3utils.parametercheck(key, configuration)
    if min then
      if #list < max then
        return key
      else
         return 'unpaired'
      end
    else
      return 'unpaired'
    end
  end
end

--- Classifies a list containing the actual command line arguments against
--- a CLI configuration table.
-- This function takes a list of elements representing the actual command
-- line arguments and classifies it according to a CLI configuration
-- table.
-- @param List containing the arguments.
-- @param configuration The CLI table configuration.
-- @return Table containing the options and their corresponding
-- arguments, if any. The `unpaired` option represents arguments without
  -- associated options.
-- @return Table containing the unknown flags.
function l3utils.classify(arguments, configuration)
  local result, key, err = { unpaired = {} }, 'unpaired', {}
  local a, b
  for _, argument in ipairs(arguments) do

    a, _, b = string.find(argument, '^%-%-(%w.*)$')

    if a then
      key = l3utils.keyresolve(b, configuration)

      if not key then
        table.insert(err, b)
        key = 'unpaired'
      end

      result[key] = l3utils.ensure(result[key], {})
      key = l3utils.keycheck(key, configuration, result[key])
    else
      a, _, b = string.find(argument, '^%-(%w.*)$')

      if a then
        key = l3utils.keyresolve(b, configuration)
        if not key then
          table.insert(err, b)
          key = 'unpaired'
        end
        result[key] = l3utils.ensure(result[key], {})
        key = l3utils.keycheck(key, configuration, result[key])
      else
        key = l3utils.keycheck(key, configuration, result[key])
        table.insert(result[key], argument)
      end

    end

  end
  return result, err
end

--- Provides a friendly representation of table elements.
-- This function provides a pretty printing feature for representing
-- table elements. If a value different other than `table` is provided,
-- its string representation is returned instead.
-- @param t The element to be printed, potentially a table.
-- @return A textual representation of the element.
function l3utils.prettyprint(t)
  if type(t) ~= 'table' then
    return tostring(t)
  end

  local f = t[1] and ipairs or pairs
  local result = '{'
  local comma = ''

  for k, v in f(t) do
    result = result .. comma .. ' ' .. tostring(k) ..
             ' --> ' .. l3utils.prettyprint(v)
    comma = ','
  end

  return result .. ' }'
end

-- export module
return l3utils
