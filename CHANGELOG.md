# Changelog

All notable changes to the `l3build` bundle since the start of 2018
will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
this project uses date-based 'snapshot' version identifiers.

## [Unreleased]

### Added

- Variable `xetexnopdf` (issue \#448)
- Variable `checkpatterns` (issue \#449)

### Changed

- Align `\SHOWPDFTAGS` markers (may require `.tlg` update)

### Fixed

- Skip LuaTeX-specific log normalization for `\SHOWPDFTAGS` output (issue \#443)

## [2025-12-24]

### Changed

- Normalize line ends in show-pdf-tags xml
- Update `\SHOWPDFTAGS` doc

## [2025-12-19]

### Added

- `\SHOWPDFTAGS` inserts the `show-pdf-tags` XML tree into the log file.

### Changed

- Clarify doc for `tdslocations` and `tdsdirs`
- Clarify nature of ISO date format

## [2025-09-03]

### Fixed

- Minor formatting issue in normalization

## [2025-09-02]

### Changed

- Extend normalization of `Lua function` lines
- Normalize `luacall` lines

## [2025-07-03]

### Fixed

- Support use of `\TIMO` with updated ConTeXt

## [2025-07-02]

### Fixed

- For tests created by `unpack`, `exludetests` was inverted

### Changed

- Support test file extensions with multiple dot separated components
- Support updated ConTeXt log formatting

## [2025-05-08]

### Fixed

- Missing `os_concat` required on Windows

## [2025-05-07]

### Added

- `halferrorline` and `errorline` vars (issue \#258)

### Changed

- Support `recordstatus` in a platform-neutral way (issue \#383)
- Use `[nl]` no `^^M` when marking linebreaks in `\SHOWFILE` (issue \#409):
  may require `.tlg` rebuilds

### Fixed

- Interaction between options `--dev` and `--show-saves`/`-S` (issue \#411)

## [2025-02-23]

### Changed

- Initialize all boolean config variables
- Normalize `at lines ...` statements for overfull and underfull boxes
  (may require `.tlg` update)

### Fixed

- Skip README rename when this has no extension (issue \#388)

## [2024-10-16]

### Added

- `--dev` switch to run tests using development format

## [2024-10-08]

### Fixed

- Test for uncompleted conditionals in tests (may require `.tlg` update)
- Global `typesetopts` no longer ignored for `luatex` and `lualatex` (issue \#351)
- Handling of spaces in options

## [2024-05-27]

### Changed

- Respect `--rerun` in `doc` target (issue \#112)

### Fixed

- Skip unknown engines correctly in `l3build save`
- Handling of environment settings in some cases (issue \#353)

## [2024-02-08]

### Changed

- Extend normalization of line numbers to include those wrapped by LaTeX in
  text `on line ...`
- Suppress `l3msg` message wrapping

## [2024-01-18]

### Added

- Switch `-s|--stdengine` to run a set of tests only with the standard engine
  even where this varies between configs (issue \#343)

### Removed

- Switch `--force|-f`

## [2024-01-09]

### Fixed

- Type of return value of `runtest_tasks()` in doc
- Print failures correctly when these occur in multiple configurations
  including the core (`build`) one

## [2024-01-04]

### Changed

- Throw warnings on unknown doc name(s)
- Always execute `runtest_tasks()` if set (issue \#327)
- Print failures correctly when these occur in multiple configurations

## [2023-12-15]

### Fixed

- Test for blank `runtest_tasks()` (issue \#327)

## [2023-12-13-2]

- Correct setup for script running in TeX Live

## [2023-12-13]

### Fixed

- Syntax warning on Windows with some test setups

## [2023-12-12]

### Changed

- Document default value of `ctanpkg` as a valid lua expression
- Improve log for failed checks with no diff files
- Document full syntaxes of `\SHOWFILE` and `\ASSERT(STR)`

### Fixed

- Short-circuit `check --rerun` if `testdir` doesn't exist
- Retain errorlevel on Windows during `check` target

## [2023-11-01]

### Changed

- Drop duplicate backslashes in doc

### Fixed

- Support non-ASCII filenames that fall within the system codepage on Windows
  (see \#122)

## [2023-09-13]

### Added

- Document ConTeXt as supported `checkformat`

### Changed

- Extend version string normalization during checks
  (see issue \#96)

- Extend excludefiles to cover `build.lua` (see \#286)

### Fixed

- Return passing errorlevel if BibTeX issues warnings
  (see \#260)
- Respect `excludefiles` when doing (local) installation

## [2023-09-07]

### Changed

- Refine `-utc` support
- Apply `checkopts` in addition to engine-specific options

## [2023-09-05]

### Changed

- Initialize the random seed with the current time so `--shuffle` produces different orders each run.
- Normalize more `luaotfload` cache lines
- Apply `-utc` switch for LuaTeX when using a fixed epoch value

## [2023-07-20]

- Set `-kanji-internal=euc` when building pLaTeX

## [2023-07-17]

### Changed

- Improve stdout "Running l3build with target ..."
- Quote configuration name used in stdout
- Update one leftover outdated doc for `unpackexe`: defaults to `pdftex`
- Building pLaTeX format now uses e-upTeX engine
- Normalize more `luaotfload` path data (see issue \#301)
- Update ConTeXt settings to allow for LuaTeX and LuaMetaTeX runs
- Improve doc for default `stdengine`

### Fixed

- Avoid setting `TEMXFCNF` for ConTeXt (issue \#232)

## [2023-03-27]

### Fixed

- All LuaTeX `.tlg` files were wrongly considered not engine-specific.
  Introduced in #292 which tried to fix #291.

## [2023-03-22]

### Changed

- Default value of `maxprintline` is now `9999`
  (may require `.tlg` updates: see docs)

### Fixed

- Apply needed luatex-specific log normalization, even when `--rerun` is used
  (issue \#291)

## [2023-03-08]

### Changed

- Generalize normalization of ghostscript version in PDF-based tests
- Include UNIX timestamps in generated ZIP files
- Normalize pdfTeX `.enc` file loading

### Fixed

- Ensure when used, value of `ps2pdfopts` is surrounded by a space on both sides

## [2023-02-26]

### Changed

- Run engine sanity check per config

### Fixed

- Restore epoch settings for `dvitopdf()`
- Use plural form of variable `ps2pdfopts` consistently in code and doc, and
  retain compatibility with singular form `ps2pdfopt` (issue \#275)
- Remove the last trace of dropped variable `stdconfig`

## [2023-02-20]

### Changed

- Unify `testdir` by dropping possibly trailing `.lua` passed to `--config`

### Fixed

- Ensure directories `testdir` and `resultdir` exist when `--dirty` is set
- epoch settings with xetex

## [2023-02-16]

### Changed

- Drop a redundant setup line for upTeX
- Normalize more Lua stack trace data (may require `.tlg` rebuild)

### Fixed

- Ensure `texmf.cnf` work correctly for `dvips`

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

- Normalize GhostScript version in PDF-based tests
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
  on all of them by default. (issue \#214)

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
- Placement of PDF files in subdirectory locations (issue \#209)
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

- Normalize Lua function calls (issue \#127) - may require `.tlg` update
- LuaTeX from TL'21 is no longer 'off by one' in log files - may require
  `.tlg` update

### Fixed

- Installation now supports deeper directory levels (issue \#182)
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

- Refinement of PDF test normalization

## [2020-03-12]

### Added

- Option `ps2pdfopt`

### Changed

- Normalize `/ID` lines in PDF comparisons
- Normalize `%%` lines in PDF comparisons

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
  (issue \#90)

## [2020-02-03]

### Changed

- Normalize out DVI header lines

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

- New `\ASSERT` and `\ASSERTSTR` functions (issue \#102)

### Changed

- Avoid normalization of (u)pTeX data when this is standard engine
  (fixes #103)
- Normalize Lua data references (#107)
- Extend `runtest_task()` to pass run number
- Allow `regression-test` to load when e-TeX is unavailable (fixes #105)

### Fixed

- Location of `testsuppdir` when multiple configurations are used

## [2019-10-02]

### Added

- `docinit_hook()`

### Changed

- Normalize out file paths in all cases

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

- Back out change for normalization of LuaTeX v1.10 stack information
  (timing issue: will reintroduce later)

### Fixed

- Correct test for LuaTeX (see #93)

## [2019-06-26]

### Added

- Support for HarfTeX (see #92)

### Changed

- Support for normalization of LuaTeX v1.10 stack information
  (may require new `.tlg` files)

### Fixed

- Support for spaces in paths when typesetting (see #91)

## [2019-06-18]

### Added

- Switch `--show-log-on-error` for use with `--halt-on-error`. Results in the `.log` file
  being show in full on the console to aid in non-interactive debugging.

### Changed

- Moved LuaTeX-specific font cache normalization

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

- Normalize date lines to contain "...-..-.." rather than removing
  (including normalizing version data in such lines): note that
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
- Tweaks to PDF-based normalization: new `.tpf` files will be required
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

- Normalize dates to placeholder "YYYY-MM-DD": may require `.tlg` updates

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
- Normalization of LuaTeX-derived `tlg` files, in preparation for
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

- Normalization for upcoming LuaTeX 1.07 release

### Fixed

- Behavior of check on Windows when using standard `fc` tool

## [2018-01-10]

## Added

- Target `manifest` for construction of file manifests automatically
- Variable `auxfiles`
- Option `--dry-run` for installation/cleaning
- Option `--texmfhome`  to allow customization of installation
- Option `--shuffle` to run tests in a random order

### Changed

- Sort list of tests to avoid system-dependent ordering
- Split `l3build` into multiple files for improved maintenance

### Fixed

- Issue with `recordstatus`

### Removed

- Rationalize short option names: removed `-d`, `-E`, `-r`
- Target `cmdcheck`: specific to LaTeX kernel work

[Unreleased]: https://github.com/latex3/l3build/compare/2025-12-24...HEAD
[2025-12-24]: https://github.com/latex3/l3build/compare/2025-12-19...2025-12-24
[2025-12-19]: https://github.com/latex3/l3build/compare/2025-09-03...2025-12-19
[2025-09-03]: https://github.com/latex3/l3build/compare/2025-09-02...2025-09-03
[2025-09-02]: https://github.com/latex3/l3build/compare/2025-07-03...2025-09-02
[2025-07-03]: https://github.com/latex3/l3build/compare/2025-07-02...2025-07-03
[2025-07-02]: https://github.com/latex3/l3build/compare/2025-05-08...2025-07-02
[2025-05-08]: https://github.com/latex3/l3build/compare/2025-05-07...2025-05-08
[2025-05-07]: https://github.com/latex3/l3build/compare/2025-02-23...2025-05-07
[2025-02-23]: https://github.com/latex3/l3build/compare/2024-10-16...2025-02-23
[2024-10-16]: https://github.com/latex3/l3build/compare/2024-10-08...2024-10-16
[2024-10-08]: https://github.com/latex3/l3build/compare/2024-05-27...2024-10-08
[2024-05-27]: https://github.com/latex3/l3build/compare/2024-02-08...2024-05-27
[2024-02-08]: https://github.com/latex3/l3build/compare/2024-01-18...2024-02-08
[2024-01-18]: https://github.com/latex3/l3build/compare/2024-01-09...2024-01-18
[2024-01-09]: https://github.com/latex3/l3build/compare/2024-01-04...2024-01-09
[2024-01-04]: https://github.com/latex3/l3build/compare/2023-12-15...2024-01-04
[2023-12-15]: https://github.com/latex3/l3build/compare/2023-12-13-2...2023-12-15
[2023-12-13-2]: https://github.com/latex3/l3build/compare/2023-12-13...2023-12-13-2
[2023-12-13]: https://github.com/latex3/l3build/compare/2023-12-12...2023-12-13
[2023-12-12]: https://github.com/latex3/l3build/compare/2023-11-01...2023-12-12
[2023-11-01]: https://github.com/latex3/l3build/compare/2023-09-13...2023-11-01
[2023-09-13]: https://github.com/latex3/l3build/compare/2023-09-07...2023-09-13
[2023-09-07]: https://github.com/latex3/l3build/compare/2023-09-05...2023-09-07
[2023-09-05]: https://github.com/latex3/l3build/compare/2023-07-20...2023-09-05
[2023-07-20]: https://github.com/latex3/l3build/compare/2023-07-17...2023-07-20
[2023-07-17]: https://github.com/latex3/l3build/compare/2023-03-27...2023-07-17
[2023-03-27]: https://github.com/latex3/l3build/compare/2023-03-22...2023-03-27
[2023-03-22]: https://github.com/latex3/l3build/compare/2023-03-08...2023-03-22
[2023-03-08]: https://github.com/latex3/l3build/compare/2023-02-26...2023-03-08
[2023-02-26]: https://github.com/latex3/l3build/compare/2023-02-20...2023-02-26
[2023-02-20]: https://github.com/latex3/l3build/compare/2023-02-16...2023-02-20
[2023-02-16]: https://github.com/latex3/l3build/compare/2022-11-10...2023-02-16
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
