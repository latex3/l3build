--[[

File l3build-complete.lua Copyright (C) 2018,2020,2021 The LaTeX Project

It may be distributed and/or modified under the conditions of the
LaTeX Project Public License (LPPL), either version 1.3c of this
license or (at your option) any later version.  The latest version
of this license is in the file

   http://www.latex-project.org/lppl.txt

This file is part of the "l3build bundle" (The Work in LPPL)
and all files in that bundle must be distributed together.

-----------------------------------------------------------------------

The development version of the bundle can be found at

   https://github.com/latex3/l3build

for those people who are interested.

--]]

local insert = table.insert
local match  = string.match
local gsub   = string.gsub
local sort   = table.sort
local concat = table.concat

function complete(name)
  if name == "zsh" then
    complete_zsh()
  end
end

function complete_zsh()
  local zsh_template = [=[
#compdef {{ scriptname }}

__l3build() {
  local targets=(
    {{ targets }}
  )
  local options=(
    {{ options }}
  )
  _arguments -s -S $options \
    "1:target:(($targets))" \
    "*::name:->name"
  case $state in
    name)
      case $words[1] in
        complete)
          _arguments '1:shell:(zsh)'
        ;;
      esac
    ;;
  esac
}

if [[ $zsh_eval_context[-1] == loadautofunc ]]; then
  # autoload from fpath, call function directly
  __l3build "$@"
else
  # eval/source/. command, register function for later
  compdef __l3build {{ scriptname }}
fi
]=]
  local function setup_list(list)
    local longest = 0
    for k,_ in pairs(list) do
      if k:len() > longest then
        longest = k:len()
      end
    end
    -- Sort the options
    local t = { }
    for k,_ in pairs(list) do
      insert(t, k)
    end
    sort(t)
    return longest,t
  end

  local scriptname = "l3build"
  if not (match(arg[0], "l3build%.lua$") or match(arg[0],"l3build$")) then
    scriptname = arg[0]
  end
  local targets = {}
  local _,t = setup_list(target_list)
  for _,k in ipairs(t) do
    local target = target_list[k]
    if target["desc"] then
      insert(targets, "'" .. k .. ":" .. gsub(
        target["desc"], "[: ]", "\\%0"
      ) .. "'")
    end
  end
  local options = {}
  _,t = setup_list(option_list)
  local stop_completion_map = {option = "-", target = ":", name = "*"}
  for _,k in ipairs(t) do
    local opt = option_list[k]
    if opt["desc"] then
      local desc = "'[" .. gsub(
        gsub(
          opt["desc"], "'", "'\\''"
        ), "[:%[%]]", "\\%0"
      ) .. "]'"
      local prefix = ""
      if opt["stop_completions"] then
        local stop_completions = {}
        for _, stop_completion in ipairs(opt["stop_completions"]) do
          insert(stop_completions, stop_completion_map[stop_completion])
        end
        prefix = "'(" .. concat(stop_completions, " ") .. ")'"
      end
      local option = "--" .. k
      if opt["short"] then
        option = "{--" .. k .. ",-" .. opt["short"] .. "}"
      end
      local suffix = ":"
      if opt["type"] == "boolean" then
        suffix = ""
      end
      if opt["complete"] then
        suffix = suffix .. opt["complete"] .. ":"
      end
      if opt["complete"] == "lua_file" then
        suffix = suffix .. "'_files -g \"*.lua\"'"
      elseif opt["complete"] == "file" then
        suffix = suffix .. "_files"
      elseif opt["complete"] == "engine" then
        suffix = suffix .. "'(pdftex xetex luatex ptex uptex)'"
      end
      insert(options, prefix .. option .. desc .. suffix)
    end
  end
  local output = gsub(
    gsub(
      gsub(
        zsh_template, "{{ targets }}", concat(targets, "\n    ")
      ), "{{ options }}", concat(options, "\n    ")
    ), "{{ scriptname }}", scriptname
  )
  print(output)
end
