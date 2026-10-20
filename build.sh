#!/usr/bin/env bash

mkdir -p bin

# -o:speed by default, or -debug (with leak tracking in main) for `--debug`.
if [[ "$1" == "--debug" ]]; then
    odin build src/ -collection:pkgs=pkgs -debug -out:bin/mimir-dbg -vet
    echo "Debug build done."
else
    odin build src/ -collection:pkgs=pkgs -o:speed -out:bin/mimir -vet
    echo "Build done."
fi
