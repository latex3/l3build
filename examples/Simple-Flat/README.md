L3BUILD `simple-flat` example
=================================================

This is a good example demonstrating a generic use case for a simple package using `l3build`.

This package is set up to produce two PDF files: one including the user documentation for the package, and the second, with ‘`-code`’ suffix, which includes both the user documentation and the typeset package code.
Note that these are produced by the two `.tex` files, which simply set typesetting options and read in the `.dtx` docstrip file so only one source file needs to be maintained.

A variety of alternative docstrip arrangements can be set up to similar effect; the arrangement here is chosen for simplicity.
As the `.dtx` package file grows larger, it may be sensible to split it up into multiple files, including separating the user documentation from the code itself.

-----

Copyright (C) 2014-2024 The LaTeX Project <br />
<https://latex-project.org/> <br />
All rights reserved.
