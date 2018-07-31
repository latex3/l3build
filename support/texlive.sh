#!/usr/bin/env sh

# This script is used for testing using Travis
# It is intended to work on their VM set up: Ubuntu 12.04 LTS
# A minimal current TL is installed adding only the packages that are
# required

# See if there is a cached version of TL available
export PATH=/tmp/texlive/bin/x86_64-linux:$PATH
if ! command -v texlua > /dev/null; then
  # Obtain TeX Live
  wget http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
  tar -xzf install-tl-unx.tar.gz
  cd install-tl-20*

  # Install a minimal system
  ./install-tl --profile=../support/texlive.profile

  cd ..
fi

# Needed for any use of texlua even if not testing LuaTeX
tlmgr install luatex

# Required to build plain and LaTeX formats:
# TeX90 plain for unpacking, pdfLaTeX, LuaLaTeX and XeTeX for tests
# The Lua libs and Latin Modern font avoid a few warnings with more
# recent LaTeX2e kernels (which load Unicode as standard)
tlmgr install cm ec etex etex-pkg knuth-lib latex-bin lm lualibs luaotfload \
  metafont mfware tex tex-ini-files unicode-data xetex
  
# Additional requirements for (u)pLaTeX, done with no dependencies to
# avoid large font payloads
tlmgr install --no-depends babel ptex uptex ptex-base uptex-base ptex-fonts \
  uptex-fonts platex uplatex

# Keep no backups (not required, simply makes cache bigger)
tlmgr option -- autobackup 0

# Update the TL install but add nothing new
tlmgr update --self --all --no-auto-install
