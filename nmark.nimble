# Package

version       = "0.1.0"
author        = "kyoheiu"
description   = "Yet another markdown parser, based on CommonMark"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["nmark"]
skipDirs      = @["nmark"]


# Dependencies

requires "nim >= 1.4.2"