#!/usr/bin/env zsh

alias C="dart bin/compile.dart"

set -e

TYPE=$1

# remove parmeters $1
shift 1

case $TYPE in
autotools)
    ## Compile autotools example (libffi)
    C c autotools -C example/libffi $@
    ;;
cmake)
    ## Compile cmake example (zlib)
    C c cmake -C example/zlib $@
    ;;
*)
    echo "Usage: $0 [autotools|cmake]"
    exit 1
    ;;
esac
