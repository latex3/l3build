#!/usr/bin/env texlua

bundle = "bundle-flat"

packtdszip = true

kpse.set_program_name("kpsewhich")
dofile(kpse.lookup("l3build.lua"))
