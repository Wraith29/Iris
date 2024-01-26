# Package

version       = "0.1.0"
author        = "Isaac Naylor"
description   = "A Web Framework"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 2.1.1"
requires "jsony"

# Tasks

task docs, "Build the Documentation":
    exec "nim doc --project --index:on -o:docs ./src/solstice.nim"

task test, "Run all rests":
    exec "testament cat ."
    exec "testament html"
