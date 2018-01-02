#!/usr/bin/env texlua

module = "simple-tree"

sourcefiledir = "code"
docfiledir    = "doc"
typesetfiles  = {"*.dtx","*.tex"}
packtdszip    = true -- recommended for "tree" layouts

kpse.set_program_name("kpsewhich")
dofile(kpse.lookup("l3build.lua"))
