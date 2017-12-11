#!/usr/bin/env texlua

bundle = "bundle-tree"

packtdszip = true

kpse.set_program_name("kpsewhich")
dofile(kpse.lookup("l3build.lua"))
