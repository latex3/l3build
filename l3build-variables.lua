--[[

File l3build-variables.lua Copyright (C) 2018 The LaTeX3 Project

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

local exit             = os.exit

-- "module" is a deprecated function in Lua 5.2: as we want the name
-- for other purposes, and it should eventually be 'free', simply
-- remove the built-in
if type(module) == "function" then
  module = nil
end

-- Ensure the module and bundle exist
module = module or ""
bundle = bundle or ""

-- Directory structure for the build system
-- Use Unix-style path separators
currentdir = "."
maindir    = maindir or currentdir

-- Substructure for file locations
docfiledir    = docfiledir    or currentdir
sourcefiledir = sourcefiledir or currentdir
supportdir    = supportdir    or maindir .. "/support"
testfiledir   = testfiledir   or currentdir .. "/testfiles"
testsuppdir   = testsuppdir   or testfiledir .. "/support"

-- Structure within a development area
builddir   = builddir   or maindir .. "/build"
distribdir = distribdir or builddir .. "/distrib"
localdir   = localdir   or builddir .. "/local"
testdir    = testdir    or builddir .. "/test"
typesetdir = typesetdir or builddir .. "/doc"
unpackdir  = unpackdir  or builddir .. "/unpacked"

-- Substructure for CTAN release material
ctandir = ctandir or distribdir .. "/ctan"
tdsdir  = tdsdir  or distribdir .. "/tds"
tdsroot = tdsroot or "latex"

-- Location for installation on CTAN or in TEXMFHOME
if bundle == "" then
  moduledir = tdsroot .. "/" .. module
  ctanpkg   = ctanpkg or module
else
  moduledir = tdsroot .. "/" .. bundle .. "/" .. module
  ctanpkg   = ctanpkg or bundle
end

-- File types for various operations
-- Use Unix-style globs
-- All of these may be set earlier, so a initialised conditionally
auxfiles           = auxfiles           or {"*.aux", "*.lof", "*.lot", "*.toc"}
bibfiles           = bibfiles           or {"*.bib"}
binaryfiles        = binaryfiles        or {"*.pdf", "*.zip"}
bstfiles           = bstfiles           or {"*.bst"}
checkfiles         = checkfiles         or { }
checksuppfiles     = checksuppfiles     or { }
cleanfiles         = cleanfiles         or {"*.log", "*.pdf", "*.zip"}
demofiles          = demofiles          or { }
docfiles           = docfiles           or { }
excludefiles       = excludefiles       or {"*~"}
installfiles       = installfiles       or {"*.sty","*.cls"}
makeindexfiles     = makeindexfiles     or {"*.ist"}
scriptfiles        = scriptfiles        or { }
sourcefiles        = sourcefiles        or {"*.dtx", "*.ins"}
tagfiles           = tagfiles           or {"*.dtx"}
textfiles          = textfiles          or {"*.md", "*.txt"}
typesetdemofiles   = typesetdemofiles   or { }
typesetfiles       = typesetfiles       or {"*.dtx"}
typesetsuppfiles   = typesetsuppfiles   or { }
typesetsourcefiles = typesetsourcefiles or { }
unpackfiles        = unpackfiles        or {"*.ins"}
unpacksuppfiles    = unpacksuppfiles    or { }

-- Roots which should be unpacked to support unpacking/testing/typesetting
checkdeps   = checkdeps   or { }
typesetdeps = typesetdeps or { }
unpackdeps  = unpackdeps  or { }

-- Executable names plus following options
typesetexe = typesetexe or "pdflatex"
unpackexe  = unpackexe  or "tex"
zipexe     = zipexe     or "zip"

checkopts   = checkopts   or "-interaction=nonstopmode"
typesetopts = typesetopts or "-interaction=nonstopmode"
unpackopts  = unpackopts  or ""
zipopts     = zipopts     or "-v -r -X"

-- Engines for testing
checkengines = checkengines or {"pdftex", "xetex", "luatex"}
checkformat  = checkformat  or "latex"
stdengine    = stdengine    or "pdftex"

-- Configs for testing
checkconfigs = checkconfigs or {"build"}

-- Enable access to trees outside of the repo
-- As these may be set false, a more elaborate test than normal is needed
if checksearch == nil then
  checksearch = true
end
if typesetsearch == nil then
  typesetsearch = true
end
if unpacksearch == nil then
  unpacksearch = true
end

-- Additional settings to fine-tune typesetting
glossarystyle = glossarystyle or "gglo.ist"
indexstyle    = indexstyle    or "gind.ist"

-- Supporting binaries and options
biberexe      = biberexe      or "biber"
biberopts     = biberopts     or ""
bibtexexe     = bibtexexe     or "bibtex8"
bibtexopts    = bibtexopts    or "-W"
makeindexexe  = makeindexexe  or "makeindex"
makeindexopts = makeindexopts or ""

-- Forcing epoch
if forcecheckepoch == nil then
  forcecheckepoch = true
end
if forcedocepoch == nil then
  forcedocepoch = false
end

-- Other required settings
asciiengines = asciiengines or {"pdftex"}
checkruns    = checkruns    or 1
epoch        = epoch        or 1463734800
if flatten == nil then
  flatten = true
end
maxprintline = maxprintline or 79
packtdszip   = packtdszip   or false
typesetcmds  = typesetcmds  or ""
typesetruns  = typesetruns  or 2
versionform  = versionform  or ""
recordstatus = recordstatus or false

-- Extensions for various file types: used to abstract out stuff a bit
bakext = bakext or ".bak"
dviext = dviext or ".dvi"
logext = logext or ".log"
lveext = lveext or ".lve"
lvtext = lvtext or ".lvt"
pdfext = pdfext or ".pdf"
psext  = psext  or ".ps"
tlgext = tlgext or ".tlg"

-- Manifest options
manifestfile = manifestfile or "MANIFEST.md"
