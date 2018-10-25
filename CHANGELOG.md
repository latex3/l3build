# Changelog
All notable changes to the `l3build` bundle since the start of 2018
will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
this project uses date-based 'snapshot' version identifiers.

## [Unreleased]

## Added

- `\SHOWFILE` command

## Fixed

- Support for spaces in directory names (fixes #76)
- Support relative directories as argument to `--texmfhome`

## [2018-09-23]

## Changed

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

[Unreleased]: https://github.com/latex3/l3build/compare/2018-09-26...HEAD
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
