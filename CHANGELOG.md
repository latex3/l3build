# Changelog
All notable changes to the `l3build` bundle since the start of 2018
will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
this project uses date-based 'snapshot' version identifiers.

## [Unreleased]

## [2022-11-10]

### Changed
- Suppress (new) LaTeX version data at end of `.log`

### Fixed
- Allow for local override of `ctanupload` variable

## [2022-09-15]

### Fixed
- Copying of nested directories

## [2022-04-19]

### Changed
- Normalise GhostScript version in PDF-based tests
- Sort list of names of difference files for failing tests.

## [2022-04-12]

### Added
- Basic support for `make4ht`

### Changed
- Support `bidi` version string in `\special` lines (closes \#226)

## [2022-03-15]

### Changed
- When `\pdfmeta_set_regression_data:` is defined it is used
  to set metadata
- Support multiple configurations in bundles

### Fixed
- Correctly normalize luaotfload font cache path

## [2022-02-24]

### Fixed
- Creation of subdirectories in TDS structures on Unix-like systems

- use `form-string` rather than `form` for all curl fields to avoid
  misinterpreting leading `@` or `<` eg a description starting `<p>`

- Check the boolean value returned by executing shell commands in
  `l3build-upload` and throw an error if this is false. This fixes
  the issue that previously "validation successful" was reported
  if `curl` failed.

### Changed
- Documentation of how to validate an upload

## [2021-12-14]

### Fixed
- Use correct name for `options` table in multi configuration management code

## [2021-12-09]

### Added
- Support for pre-constructed TDS-style sources (variable `tdsdirs`)
- Support for injection of tokens using `specialformats`

### Changed
- If multiple configurations are present, let `l3build clean` run
  on all of them by default. (issue #214)

## [2021-12-06]

### Fixed
- Place PDF files inside `docfiledir` in all cases

## [2021-11-29]

### Changed
- Documentation improvements
- Use `checkengines[1]` as the default for `stdengine`
- Add sanity check for `TEXMFHOME` value
- Double \ when writing the curl options, so that \
  does not need to be doubled in note and announcement texts.

### Fixed
- Installation of files when using MiKTeX (see #125)
- Incorrect line in `manifest` target (see #195)
- Placement of PDF files in subdirectory locations (issue #209)
- Detection of engine-specific tlg files for non-standard LuaTeX based engines (issues #214)

## [2021-11-24]

- Always typeset in `typesetdir` (fixes #210)

## [2021-11-12]

### Changed
- Documentation improvements

### Fixed
- Allow config names ending with 'lua', as long as they don't end with '.lua'
- All documentation files are build in a consistent environment with support
  files visible.

## [2021-08-28]

### Fixed
- Creation of zip files on Windows
- Only match filename and not full path for `exefiles`

## [2021-08-27]

### Added
- Add the `--show-saves` flag for `l3build check` to generate a list of
  `l3build save` commands to regenerate all failing tests

### Changed
- No longer call an external program to generate `zip` files and generate
  them directly instead. This disables the options `zipexe` and `zipopts`.
- Copy TDS-style zip files to main dir

## [2021-05-06]

### Fixed
- Issue when running PDF-based tests

## [2021-05-05]

### Changed
- Normalise Lua function calls (issue #127) - may require `.tlg` update
- LuaTeX from TL'21 is no longer 'off by one' in log files - may require
  `.tlg` update

### Fixed
- Installation now supports deeper directory levels (issue #182)
- The `texmfhome` directory is now created before use if required
- Crash caused by yyyy-mm-dd epoch format

### Removed
- Support for use as `texlua build.lua <target>`

## [2020-06-04]

### Added
- Store 'raw' PDF files when testing using PDFs, to allow further checks
  with e.g. PDF validators

## [2020-03-25]

### Changed
- Exclude `sourcefiles` entries from file clean-up
- Adjust defaults for TeX Live 2020 LuaHBTeX usage

## [2020-03-16]

### Changed
- Suppress PDF compression in DVI route
- Suppress PDF ID data in DVI route
- Default to `dvips` for (p)TeX
- Refinement of `/ID` line suppression

## [2020-03-13]

### Changed
- Refinement of PDF test normalisation

## [2020-03-12]

### Added
- Option `ps2pdfopt`

### Changed
- Normalise `/ID` lines in PDF comparisons
- Normalise `%%` lines in PDF comparisons

### Fixed
- Enable `cleandir()` recursively
- Install files after *all* directory cleaning/creation

## [2020-02-21]

### Changed
- Avoid temporary file when unpacking

### Deprecated
- `os_yes`: use `io.popen(...,w)` instead

## [2020-02-17]

### Added
- Variable `textfiledir`
- Table `specialtypesetting` and support data

### Changed
- Documentation improvements

### Fixed
- When `checkruns` > 1 and `recordstatus=true`, testing code would crash
  (issue #90)

## [2020-02-03]

### Changed
- Normalise out DVI header lines

### Fixed
- Allow announcement field to be empty
  (with a warning this suppresses the CTAN announcement)

## [2020-01-14]

### Fixed

- Allow for more extracted files from DocStrip

## [2019-11-27]

### Changed

- `\ASSERTSTR` no longer needs e-TeX

### Fixed

- Installation of files using the `--full` switch

## [2019-11-01]

### Added

- New `\ASSERT` and `\ASSERTSTR` functions (issue #102)

### Changed

- Avoid normalisation of (u)pTeX data when this is standard engine
  (fixes #103)
- Normalise Lua data references (#107)
- Extend `runtest_task()` to pass run number
- Allow `regression-test` to load when e-TeX is unavailable (fixes #105)

### Fixed

- Location of `testsuppdir` when multiple configurations are used

## [2019-10-02]

### Added

- `docinit_hook()`

### Changed

- Normalise out file paths in all cases

## [2019-09-30]

### Added

- New `flattentds` variable for controlling complex TDS structures
- Additional notes on `texmfdir`

### Fixed

- Copy TDS files inside subdirectories (fixes #100)

## [2019-09-29]

### Fixed

- Path searching if `texmfdir` is set but does not exist

## [2019-09-28]

### Fixed

- Typesetting when using an isolated system (use of texmfdir)

## [2019-09-25]

### Added

- New `texmfdir` variable for more complex local additions

### Fixed

- Clean out all configuration test dirs (see #98)

## [2019-09-18]

### Added

- `checkinit_hook()`

## [2019-09-14]

### Changed

- Use three typesetting runs as-standard
- Use `pdftex` not `tex` for unpacking

## [2019-08-24]

### Changed

- Include `LUAINPUTS` when setting `TEXINPUTS` for `checksearch = false`, etc.

### Fixed

- Remove `.log` file before each check run: prevent inter-engine confusion

## [2019-07-31]

### Fixed

- Interaction between secondary files in some tests

## [2019-07-30]

### Added

- Support for non-standard file layouts via `tdslocations` table

### Changed

- Only write (x)dvipdfmx specials for XeTeX and (u)pTeX (see #94)

## [2019-06-27]

### Changed

- Back out change for normalisation of LuaTeX v1.10 stack information
  (timing issue: will reintroduce later)

### Fixed

- Correct test for LuaTeX (see #93)

## [2019-06-26]

### Added

- Support for HarfTeX (see #92)

### Changed

- Support for normalisation of LuaTeX v1.10 stack information
  (may require new `.tlg` files)

### Fixed

- Support for spaces in paths when typesetting (see #91)

## [2019-06-18]

### Added

- Switch `--show-log-on-error` for use with `--halt-on-error`. Results in the `.log` file
  being show in full on the console to aid in non-interactive debugging.

### Changed

- Moved LuaTeX-specific font cache normalisation

## [2019-02-10]

### Fixed

- Handling of ASCII engines
- Execution of all tests by `ctan` target (see #85)

## [2019-02-06]

### Added

- Table-based control of binary/format combinations: `specialformats`
  (see #84)
- Switch `--debug` for chasing problems with the `upload` target

### Changed

- The `uploadconfig.update` field by default now automatically detects whether it
  needs to be `true` or `false`
- The `tag` target now allows no tag name to allow for setting this programmatically
  within a `build.lua` script
- Better support for multiple LuaTeX-like engines

### Fixed

- Uploading via Windows should now work

## [2018-12-23]

### Added

- Switch `--email` for providing upload email address
- Switch `-F|--file` for providing upload announcement from file
- Switch `-m|--message` for providing upload announcement from command line

### Changed

- Enable `--dry-run` option for `upload` target
- Enable tag/version to be passed as optional argument to `upload` target

### Fixed

- Packaging of some team-specific files
- Handling of upload data containing newlines (Windows only)

## [2018-12-18]

### Changed

- Add new `upload` target which uses `curl` with the CTAN API to send a package
  for release (see #1)

## [2018-11-08]

### Changed

- Strip leading spaces from file loading/page number lines (see #78)

### Fixed

- Print test failures correctly per-config (see #77)

## [2018-10-30]

### Fixed

- Substitution of spaces in Unix paths (see #76)

## [2018-10-25]

### Added

- `\SHOWFILE` command

### Changed

- Better support for multiple LuaTeX engines (see #75)

## Fixed

- Support for spaces in directory names (fixes #76)
- Support relative directories as argument to `--texmfhome`

## [2018-09-23]

### Changed

- Entries in `scriptfiles` are excluded from `installfiles`
- Use a per-config directory for running tests
- Enable use of local `texmf.cnf` file in tests and documentation
- New `ctanreadme` variable

## [2018-09-21]

### Changed

- Normalise date lines to contain "...-..-.." rather than removing
  (including normalising version data in such lines): note that
  `.tlg` file updates may be required after this change
- Explicitly exclude `.fd` file lines

## [2018-08-07]

### Changed
- Suppress file name info in PDF output for included images, etc.

### Fixed
- Issue with creation of CTAN releases for bundles

## [2018-08-04]

### Added
- `ctanzip` variable
- `--full` option

### Changed
- Run PDF-based tests for all engines
- Tweaks to PDF-based normalisation: new `.tpf` files will be required
- The `--halt-on-error|-H` setting now applies to multiple configs

### Fixed
- Testing using `.lve` files
- Tagging with new approach to top-level targets

## [2018-08-02]

### Added
- `CHANGELOG.md`
- `--dirty` option
- `includetests` and `excludetests` variables for controlling which tests
  run
- `target_list` table to allow control of targets without redefining
  `main()`

### Changed
- PDF-based testing now uses 'digested' PDF file for comparison,
  working from dedicated `.pvt` input files

### Removed
- `--pdf|-p` command line switch

## [2018-05-10]

### Changed
- Revert appearance of date lines in `.tlg` files:
  this is on balance problematic

## [2018-05-06]

### Added
- Variable `dynamicfiles` to be cleaned between each test run

### Changed
- Normalise dates to placeholder "YYYY-MM-DD": may require `.tlg` updates

### Fixed
- Include dot files in `tree()` (fixes #30)

## [2018-03-26]

### Changed
- Omit ISO date lines in `.tlg` files

## [2018-03-24]

### Changed
- Allow 'short cut' of check runs
- Support for upcoming LaTeX kernel release functions

## [2018-03-10]

### Changed
- Add `#!` line for POSIX users
- Set POSIX u+x on `l3build.lua`

### Fixed
- Handling of script name with or without extension

## [2018-03-09]

### Fixed
- Pass through script name correctly with new set up

## [2018-03-08]

### Added
- Target `tag`, variable `tagfiles` and function `update_tag()`
- Variables `scriptfiles` and `scriptmanfiles` to support installation
  of scripts

### Changed
- `l3build` can now be run as a top-level script rather than using
  `texlua build.lua ...`
- Normalisation of LuaTeX-derived `tlg` files, in preparation for
  TeX Live 2018

### Deprecated
- Use of wrapper `build.lua` script to call `l3build`: the new
  top-level script approach is preferred

### Removed
- Target `setversion` and variable `versionfiles`

## [2018-02-20]

### Changed
- Allow for `checkopts` adding code/files

### Fixed
- Creation of 'structured' CTAN releases
- Quote test names correctly

## [2018-01-27]

### Added
- Target `uninstall`
- Options `--first` and `--last`

## Changed
- Normalisation for upcoming LuaTeX 1.07 release

### Fixed
- Behaviour of check on Windows when using standard `fc` tool

## [2018-01-10]

## Added
- Target `manifest` for construction of file manifests automatically
- Variable `auxfiles`
- Option `--dry-run` for installation/cleaning
- Option `--texmfhome`  to allow customisation of installation
- Option `--shuffle` to run tests in a random order

### Changed
- Sort list of tests to avoid system-dependent ordering
- Split `l3build` into multiple files for improved maintenance

### Fixed
- Issue with `recordstatus`

### Removed
- Rationalise short option names: removed `-d`, `-E`, `-r`
- Target `cmdcheck`: specific to LaTeX kernel work

[Unreleased]: https://github.com/latex3/l3build/compare/2022-11-10...HEAD
[2022-11-10]: https://github.com/latex3/l3build/compare/2022-09-15...2022-11-10
[2022-09-15]: https://github.com/latex3/l3build/compare/2022-04-19...2022-09-15
[2022-04-19]: https://github.com/latex3/l3build/compare/2022-04-12...2022-04-19
[2022-04-12]: https://github.com/latex3/l3build/compare/2022-03-15...2022-04-12
[2022-03-15]: https://github.com/latex3/l3build/compare/2022-02-24...2022-03-15
[2022-02-24]: https://github.com/latex3/l3build/compare/2021-12-14...2022-02-24
[2021-12-14]: https://github.com/latex3/l3build/compare/2021-12-09...2021-12-14
[2021-12-09]: https://github.com/latex3/l3build/compare/2021-12-06...2021-12-09
[2021-12-06]: https://github.com/latex3/l3build/compare/2021-11-29...2021-12-06
[2021-11-29]: https://github.com/latex3/l3build/compare/2021-11-24...2021-11-29
[2021-11-24]: https://github.com/latex3/l3build/compare/2021-11-12...2021-11-24
[2021-11-12]: https://github.com/latex3/l3build/compare/2021-08-28...2021-11-12
[2021-08-28]: https://github.com/latex3/l3build/compare/2021-08-27...2021-08-28
[2021-08-27]: https://github.com/latex3/l3build/compare/2021-05-06...2021-08-27
[2021-05-06]: https://github.com/latex3/l3build/compare/2021-05-05...2021-05-06
[2021-05-05]: https://github.com/latex3/l3build/compare/2020-06-04...2021-05-05
[2020-06-04]: https://github.com/latex3/l3build/compare/2020-03-25...2020-06-04
[2020-03-25]: https://github.com/latex3/l3build/compare/2020-03-16...2020-03-25
[2020-03-16]: https://github.com/latex3/l3build/compare/2020-03-13...2020-03-16
[2020-03-13]: https://github.com/latex3/l3build/compare/2020-03-12...2020-03-13
[2020-03-12]: https://github.com/latex3/l3build/compare/2020-02-21...2020-03-12
[2020-02-21]: https://github.com/latex3/l3build/compare/2020-02-17...2020-02-21
[2020-02-17]: https://github.com/latex3/l3build/compare/2020-02-03...2020-02-17
[2020-02-03]: https://github.com/latex3/l3build/compare/2020-01-14...2020-02-03
[2020-01-14]: https://github.com/latex3/l3build/compare/2019-11-27...2020-01-14
[2019-11-27]: https://github.com/latex3/l3build/compare/2019-11-01...2019-11-27
[2019-11-01]: https://github.com/latex3/l3build/compare/2019-10-02...2019-11-01
[2019-10-02]: https://github.com/latex3/l3build/compare/2019-09-30...2019-10-02
[2019-09-30]: https://github.com/latex3/l3build/compare/2019-09-29...2019-09-30
[2019-09-29]: https://github.com/latex3/l3build/compare/2019-09-28...2019-09-29
[2019-09-28]: https://github.com/latex3/l3build/compare/2019-09-25...2019-09-28
[2019-09-25]: https://github.com/latex3/l3build/compare/2019-09-18...2019-09-25
[2019-09-18]: https://github.com/latex3/l3build/compare/2019-09-14...2019-09-18
[2019-09-14]: https://github.com/latex3/l3build/compare/2019-08-24...2019-09-14
[2019-08-24]: https://github.com/latex3/l3build/compare/2019-07-31...2019-08-24
[2019-07-31]: https://github.com/latex3/l3build/compare/2019-07-30...2019-07-31
[2019-07-30]: https://github.com/latex3/l3build/compare/2019-06-27...2019-07-30
[2019-06-27]: https://github.com/latex3/l3build/compare/2019-06-26...2019-06-27
[2019-06-26]: https://github.com/latex3/l3build/compare/2019-06-18...2019-06-26
[2019-06-18]: https://github.com/latex3/l3build/compare/2019-02-10...2019-06-18
[2019-02-10]: https://github.com/latex3/l3build/compare/2019-02-06...2019-02-10
[2019-02-06]: https://github.com/latex3/l3build/compare/2018-12-23...2019-02-06
[2018-12-23]: https://github.com/latex3/l3build/compare/2018-12-18...2018-12-23
[2018-12-18]: https://github.com/latex3/l3build/compare/2018-11-08...2018-12-18
[2018-11-08]: https://github.com/latex3/l3build/compare/2018-10-30...2018-11-08
[2018-10-30]: https://github.com/latex3/l3build/compare/2018-10-25...2018-10-30
[2018-10-25]: https://github.com/latex3/l3build/compare/2018-09-26...2018-10-25
[2018-09-26]: https://github.com/latex3/l3build/compare/2018-09-23...2018-09-26
[2018-09-23]: https://github.com/latex3/l3build/compare/2018-09-21...2018-09-23
[2018-09-21]: https://github.com/latex3/l3build/compare/2018-08-07...2018-09-21
[2018-08-07]: https://github.com/latex3/l3build/compare/2018-08-04...2018-08-07
[2018-08-04]: https://github.com/latex3/l3build/compare/2018-08-02...2018-08-04
[2018-08-02]: https://github.com/latex3/l3build/compare/2018-05-10...2018-08-02
[2018-05-10]: https://github.com/latex3/l3build/compare/2018-05-06...2018-05-10
[2018-05-06]: https://github.com/latex3/l3build/compare/2018-03-26...2018-05-06
[2018-03-26]: https://github.com/latex3/l3build/compare/2018-03-24...2018-03-26
[2018-03-24]: https://github.com/latex3/l3build/compare/2018-03-10...2018-03-24
[2018-03-10]: https://github.com/latex3/l3build/compare/2018-03-09...2018-03-10
[2018-03-09]: https://github.com/latex3/l3build/compare/2018-03-08...2018-03-09
[2018-03-08]: https://github.com/latex3/l3build/compare/2018-02-20...2018-03-08
[2018-02-20]: https://github.com/latex3/l3build/compare/2018-01-27...2018-02-20
[2018-01-27]: https://github.com/latex3/l3build/compare/2018-01-10...2018-01-27
[2018-01-10]: https://github.com/latex3/l3build/compare/2017-12-12...2018-01-10
