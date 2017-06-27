Thanks for considering contributing to `l3build`: feedback, fixes and ideas are
all useful. Here, we ([The LaTeX3 Project](https://www.latex-project.org)) have
collected together a few pointers to help things along.

## Bugs

Please log bugs using the [issues](https://github.com/latex3/l3build/issues)
system on GitHub, and choose the 'bug' label. Handy information that you might
include, depending on the nature of the issue, includes

- Your version of `l3build` (`texlua l3build.lua version`)
- Your TeX system details (for example 'TeX Live 2017')
- Your operating system
- The contents of your `build.lua` file
- An 'ASCII art' explanation of your directory layout

## Feature requests

Feature requests are welcome: log them in the same way as bugs and pick
the 'Enhancement' label. We welcome feature requests for the test set up,
the build process, _etc._

## Code contributions

If you want to discuss a possible contribution before (or instead of)
making a pull request, drop a line to
[the team](mailto:latex-team@latex-project.org).

There are a few things that might look non-standard to most Lua programmers,
which come about as `l3build`'s focus is testing and building LaTeX packages:

- Our target Lua set up is `texlua` (part of LuaTeX), not standalone `lua`
- The main `l3build.lua` file is self-contained as this helps with
  bootstrapping LaTeX: we are aiming to maintain a single file with
  `.lua` dependencies
- The primary documentation is aimed at the TeX world, so is in PDF format
  and generated from `l3build.dtx`
- As far as possible, everything is done within `l3build` itself or tools
  directly available in a TeX system or as standard in the supported
  systems (Windows, MacOS, Linux)
- The `l3build` interfaces should be platform-agnostic (though it may be
  necessary of course to branch inside particular functions)

If you are submitting a pull request, notice that

- We use Travis-CI for (light) testing so add `[ci skip]` to documentation-only
  commit messages
- We favour a single linear history so will rebase agreed pull requests on to
  the `master` branch
