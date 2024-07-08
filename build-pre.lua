-- Configuration script for LaTeX "l3build" files

do
  -- this block is testing declare_option
  -- we temporarily replace option_list to make tests
  -- TODO: make it a separate test available with target `check``
  -- using custom test types (forthcoming)
  local function expect(torf,f, msg)
    local old_option_list = option_list
    option_list = {}
    local status, err = pcall(f)
    assert(not status == not torf, debug.traceback(msg or err, 2))
    option_list = old_option_list
  end
  expect(true, function()end)
  expect(false, function()error("")end)
  expect(false,function()
    declare_option(
      1, {
      type = "boolean",
    })
  end, "Names are strings.")
  expect(false,function()
    declare_option(
      "", {
      type = "boolean",
    })
  end, "Names are non void strings.")
  expect(false,function()
    declare_option(
      "", {
      type = "boolean",
    })
  end, "Long names should not start with '-'.")
  expect(false,function()
    declare_option(
      "12", "")
  end, "t should be a table.")
  expect(false,function()
    declare_option(
      "12", {
    })
  end, "type field is required.")
  expect(false,function()
    declare_option(
      "12", {
        type = 0
    })
  end, "type field must be one of `boolean`, `string`, `table`.")
  expect(false,function()
    declare_option(
      "1=", {
      type = "boolean",
    })
  end, "No `=` in option name.")
  expect(true,function()
    declare_option(
      "12", {
      type = "boolean",
      foo = "bar",
    })
    assert(option_list["12"].type == "boolean")
    assert(option_list["12"]["foo"] == "bar")
  end)
  expect(false,function()
    declare_option(
      "12", {
      type = "boolean",
    })
    declare_option(
      "12", {
      type = "boolean",
    })
  end, "Name is already used")
  -- update_option:
  expect(false,function()
    update_option(
      "foo", "")
  end, "Bad argument")
  expect(false,function()
    update_option(
      "foo", {
      type = "boolean",
    })
  end, "Only existing option")
  expect(true,function()
    declare_option(
      "foo", {
      type = "boolean",
    })
    update_option(
      "foo", {
    })
  end)
  expect(true,function()
    declare_option(
      "foo", {
      type = "boolean",
    })
    update_option(
      "foo", {
        type = "boolean",
      })
  end)
  expect(false,function()
    declare_option(
      "foo", {
      type = "boolean",
    })
    update_option(
      "foo", {
        type = "list",
      })
  end, "Different types")
  expect(true,function()
    declare_option(
      "foo", {
      type = "boolean",
      foo = "bar"
    })
    assert(option_list["foo"]["foo"] == "bar", "foo->bar")
    update_option(
      "foo", {
        foo = "baz"
      })
    assert(option_list["foo"]["foo"] == "baz", "foo->baz")
  end)
  expect(true,function()
    declare_option(
      "foo", {
      type = "boolean",
      foo = "bar"
    })
    assert(option_list["foo"]["foo"] == "bar", "foo->bar")
    assert(option_list["foo"]["bar"] == nil, "bar->nil")
    update_option(
      "foo", {
        foo = "baz",
        bar = "foo"
      }, true)
      assert(option_list["foo"]["foo"] == "bar", "foo->bar")
      assert(option_list["foo"]["bar"] == "foo", "bar->foo")
    end)
end

-- test if `custom_option` will be available in `build.lua`
declare_option(
  "custom_option", {
  type = "string",
  desc = "Custom option"
})

print("File `build-pre.lua` loaded")
