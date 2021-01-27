-- This file can be loaded at the top of a test file
-- The problem is to load a script that is one directory above.
-- texlua usage of package.path seems special
-- we add a custom package searcher to find the modules
-- also in the testdir directory, then its parent
local dirname, basename = arg[0]:match("^(.*/)([^/]*)$")
if not dirname then
  dirname, basename = "./", arg[0]
end
-- search packages 
-- setting package.path does not help texlua
local search_paths = dirname .. "?.lua;"
                  .. dirname .. "?/init.lua;"
                  .. dirname .. "../?.lua;"
                  .. dirname .. "../?/init.lua"
table.insert(package.searchers, function (name)
  local path = package.searchpath(name, search_paths)
  if path then
    return function (_name, p)
      return dofile(p)
    end, path
  else
    return "\n        [l3build searcher] file not found" .. name
  end
end)
