#!/usr/bin/env bash

mkdir -p bin

odin build src/ -collection:pkgs=pkgs -o:speed -out:bin/mimir -vet

echo "Build done."
