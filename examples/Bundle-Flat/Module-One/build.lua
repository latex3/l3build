#!/usr/bin/env texlua

bundle = "bundle-flat"
module = "module-one"
maindir = ".."

typesetfiles  = {"*.tex"}

kpse.set_program_name("kpsewhich")
dofile(kpse.lookup("l3build.lua"))
