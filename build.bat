@echo off
rem Windows build script. -o:speed by default, or -debug (with leak
rem tracking in main) for `build.bat --debug`.

if not exist bin mkdir bin

if "%~1"=="--debug" (
    odin build src -collection:pkgs=pkgs -debug -out:bin/mimir-dbg.exe -vet
    echo Debug build done.
) else (
    odin build src -collection:pkgs=pkgs -o:speed -out:bin/mimir.exe -vet
    echo Build done.
)
