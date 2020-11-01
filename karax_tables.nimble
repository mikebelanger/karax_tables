# Package

version       = "0.1.0"
author        = "Mike Belanger"
description   = "HTML table builder using Karax.  Supports primarily client (js) rendering, and partially supports server (c) side rendering."
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.4.0"

# tasks

task all_tests, "run all tests":

    # server-side
    exec "nim c -r tests/test1.nim"
    exec "nim c -r tests/test2.nim"
    exec "nim c -r tests/test3.nim"
    exec "nim c -r tests/test4.nim"
    exec "nim c -r tests/test5.nim"

    # client-side
    exec "nim js tests/test1.nim"
    exec "nim js tests/test2.nim"
    exec "nim js tests/test3.nim"
    exec "nim js tests/test4.nim"
    exec "nim js tests/test5.nim"