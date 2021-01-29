-- This is not a unit test file
-- Once unit testing is officially integrated into l3build development processing
-- this file should definitely be turned into a real unit test file.

-- From the enclosing directory run `texlua l3build-argument.pseudo-test.lua`
-- This will run with no error and print various information.

-- this file is a tester for the `declare_target` feature

local function build_require(what)
  return require("../l3build-" .. what)
end

table.insert(package.searchers,
  function ()
    return function (module)
      return dofile(module .. ".lua")
    end
  end
)
build_require("arguments")
build_require("help")
build_require("file-functions")
build_require("typesetting")
build_require("aux")
build_require("clean")
build_require("check")
build_require("ctan")
build_require("install")
build_require("unpack")
build_require("manifest")
build_require("manifest-setup")
build_require("tagging")
build_require("upload")
options.debug = true
build_require("stdmain")

local printed = ""
local saved_print = print
print = function(fmt, ...)
  if fmt then
    printed = printed .. fmt:format(...)
  end
end

local to_pretty_string
to_pretty_string = function (t, indent)
  local ans = "{" .. "\n"
  indent = (indent or "") .. "  "
  for k,v in pairs(t) do
    ans = ans .. indent .. tostring(k) .. " = "
    if type(v) == "table" then
      ans = ans .. to_pretty_string(v, indent)
    else
      ans = ans .. tostring(v)
    end
    ans = ans .. "\n"
  end
  return ans .. indent .. "\8\8}"
end
local success, ans
local function tester(...)
  return pcall(function (...)
    declare_target(...)
  end, ...)
end
success, ans = tester()
saved_print(ans)
success, ans = tester("")
saved_print(ans)
success, ans = tester("clean")
saved_print(ans)
success, ans = tester("foo")
saved_print(ans)
success, ans = tester("foo", "bar")
saved_print(ans)
success, ans = tester("foo", {})
saved_print(ans)
success, ans = tester("foo", {
  func = 421
})
local target_def = {
  desc = "My custom target",
  func = function () end
}
success, ans = tester("foo", target_def)
saved_print(ans)
saved_print("0 == " .. tostring(target_list.foo.func()))
success, ans = tester("foo", target_def)
saved_print(ans)
target_list.foo = nil
success, ans = tester("bar", "foo", target_def)
saved_print(ans)
target_list.foo = nil
success, ans = tester("bar", target_def, "foo", target_def)
saved_print(ans)
target_list.foo = nil
target_list.bar = nil
-- saved_print(to_pretty_string(target_list))
declare_target("foo", target_def, "bar", target_def)
printed = ""
help()
local function printed_test(pattern, anti)
  local S, F = "SUCCESS", "FAILURE"
  if anti then
    S, F = F, S
  end
  saved_print(printed:match("foo%(%*%)") and S or F)
end
printed_test("foo%(%*%)")
printed_test("bar%(%*%)")
printed_test("%(%*%) stands for custom targets")
printed = ""
help(true)
printed_test("foo%(%*%)", true)
printed_test("bar%(%*%)", true)
printed_test("%(%*%) stands for custom targets", true)

target_list.foo = nil
target_list.bar = nil

declare_target("foo", {
  func = function(names)
    print("func: " .. tostring(names))
  end,
  pre = function(names)
    print("pre: " .. tostring(names))
  end,
})
printed = ""
target_list.foo.func(421)
printed_test("func: 421", true)
printed = ""
target_list.foo.pre(421)
printed_test("pre: 421", true)

saved_print('DONE')