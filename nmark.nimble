# Package

version       = "0.1.0"
author        = "kyoheiu"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["nmark"]
skipDirs      = @["nmark"]


# Dependencies

requires "nim >= 1.4.2"