#!/usr/bin/env texlua

module = "simple-flat"

typesetfiles  = {"*.tex"}

kpse.set_program_name("kpsewhich")
dofile(kpse.lookup("l3build.lua"))
