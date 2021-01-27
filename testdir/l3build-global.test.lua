#!/usr/bin/env texlua

-- see local README.md

-- common header for quite all test files:
local testdir, basename = arg[0]:match("^(.*)/([^/]*)$")
if not testdir then
  testdir, basename = ".", arg[0]
end
dofile(testdir .. "/test-preflight.lua")

local tested = basename:match("^.*(l3build%-.*)%.[^%.]*test%.lua")
local l3b = require(tested)
local LU = require("luaunit")

-- test definitions

function test_global_0()
  LU.assertIs(tested, "l3build-global")
  LU.assertEquals(l3b, require(tested)) -- multi require is OK
  require(tested)["\0"] = "YOLO"
  LU.assertEquals(l3b["\0"], "YOLO") -- multi require is OK
  LU.assertIs(l3b._TYPE, "module")
  LU.assertIs(l3b._NAME, "global")
  LU.assertIsString(l3b._VERSION)
end

function test_global_require()
  LU.assertIsFunction(l3b.require)
  local name = "fake"
  l3b.package_dir_append(testdir)
  local fake = l3b.require(name)
  LU.assertIs(fake._TYPE, "module")
  LU.assertIs(fake._NAME, name)
  LU.assertIsString(fake._VERSION)
end

-- common required trailer for all test files, except the option
os.exit(LU.run())
