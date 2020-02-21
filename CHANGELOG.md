# Changelog
All notable changes to the `l3build` bundle since the start of 2018
will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
this project uses date-based 'snapshot' version identifiers.

## [Unreleased]

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
- Target `cmdcheck`: specific to LaTeX3 kernel work

[Unreleased]: https://github.com/latex3/l3build/compare/2020-02-17...HEAD
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
