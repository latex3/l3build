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

# Update the TL install but add nothing new
tlmgr update --self

# Needed for any use of texlua even if not testing LuaTeX
tlmgr install luatex

# Required to build plain and LaTeX formats including (u)pLaTeX
tlmgr install latex-bin luahbtex platex uplatex tex xetex

# Requirements for the tests
tlmgr install amsfonts etex-pkg

# Support for typesetting the docs
tlmgr install \
  alphalph   \
  atbegshi   \
  atveryend  \
  amsmath    \
  bigintcalc \
  bitset     \
  booktabs   \
  ec         \
  colortbl   \
  csquotes   \
  enumitem   \
  etexcmds   \
  fancyvrb   \
  gettitlestring \
  graphics   \
  hologo     \
  hycolor    \
  iftex      \
  intcalc    \
  kvdefinekeys \
  kvsetkeys  \
  l3packages \
  letltxmacro \
  listings   \
  ltxcmds    \
  makeindex  \
  needspace  \
  oberdiek   \
  pdfescape  \
  pdftexcmds \
  psnfss     \
  refcount   \
  rerunfilecheck \
  hyperref   \
  tools      \
  underscore \
  uniquecounter

# Keep no backups (not required, simply makes cache bigger)
tlmgr option -- autobackup 0

# Update the TL install but add nothing new
tlmgr update --all --no-auto-install
