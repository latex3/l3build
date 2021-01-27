# Testing

testing lua scripts is performed with the aid of [LuaUnit](https://luaunit.readthedocs.io/en/luaunit_v3_2_1/)

All test material related to lua is gathered in the `testdir` folder.

## Example

From the terminal, change to the `testdir` folder, then execute
```
texlua l3build-global.test.lua
```
the output should read something like
```
..
Ran 2 tests in 0.001 seconds, 2 successes, 0 failures
OK
```
Other output formats are available with options `-v` or `-o tap`.

## Organisation

Every `l3build-foo.lua` of the main directory eligible for unit testing will have a `l3build-foo.test.lua` counterpart in the testdir `folder`.

## Tricky bits

The parent directory is not one of the directories where `kpse` seeks. 
Teaching lua to look there is made in `test-preflight.lua`.

The `l3b.package_dir_append(testdir)` instruction allows
to launch the tests out of `testdir`. 
