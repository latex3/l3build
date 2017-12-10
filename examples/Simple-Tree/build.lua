#!/usr/bin/env texlua

module = "simple-tree"

sourcefiledir = "code"
docfiledir    = "doc"
typesetfiles  = {"*.dtx","*.tex"}

kpse.set_program_name("kpsewhich")
dofile(kpse.lookup("l3build.lua"))
