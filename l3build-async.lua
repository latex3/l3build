--[[

File l3build-async.lua Copyright (C) 2018-2026 The LaTeX Project

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

-- Executing external programs with os.execute waits for the external program
-- to finish before returning to Lua. This makes it harder to coordinate
-- running multiple external programs in parallel. Therefore we use an native library
-- `l3build_async_native` to provide an asynchronous execute primitive which
-- suspends the current coroutine but allows another coroutine to continue
-- until the external program returns. Since the external library is not always installed
-- we implement the same interface without concurrency in Lua.
--
-- Usage:
-- local async = require'l3build-async'
-- local executor = async.new(5) -- Never run more than 5 coroutines concurrently.
-- executor.spawn(function() -- Spawn a coroutine. async.execute can only be called inside a coroutine
--                           -- started with .spawn
--   async.execute("sleep 10")
-- end)
-- executor.run() -- Run coroutines until all spawned routines have finished.

local native_loaded, native_impl = pcall(require, 'l3build_async_native')
if native_loaded then return native_impl end

local os_type = os.type
local execute = os.execute

-- Work around a LuaTeX issue on *nix OS
if os_type ~= "windows" then
  local original_execute = execute
  function execute(...)
    return (0xFF00 & original_execute(...)) >> 8
  end
end

local dummy_executor = {}
function dummy_executor.spawn(_dummy, f)
  f()
end
function dummy_executor.run() end

return {
  new = function(concurrency) return dummy_executor end,
  execute = execute,
}
