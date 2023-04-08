#!/bin/bash

set -e

alias C="dart bin/compile.dart"


## Compile autotools example (libffi)
C autotools -C example/libffi

## Compile cmake example (zlib)
C cmake -C example/zlib
