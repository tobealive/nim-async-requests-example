# Package

version       = "0.1.0"
author        = "Turiiya"
description   = "Example that focuses on concurrent / parallel async requests"
license       = "MIT"
srcDir        = "src"
bin           = @["async_requests"]


# Dependencies

requires "nim >= 1.6.10"
requires "chronos"
