#!/usr/bin/env zsh

alias C="dart bin/compile.dart"

set -e

TYPE=$1

# remove parmeters $1
shift 1

case $TYPE in
autotools | at)
    ## Compile autotools example (libffi)
    C c autotools -C example/libffi-git-at $@
    ;;
cmake | cm)
    ## Compile cmake example (zlib)
    C c cmake -C example/zlib-git-cmake $@
    ;;
http)
    C c cmake -C example/zlib-http-cmake $@
    ;;
subpath)
    C c cmake -C example/libexpat-git-subpath-cmake $@
    ;;
all)
    C c autotools -C example/libffi-git-at $@
    C c cmake -C example/zlib-git-cmake $@
    C c cmake -C example/zlib-http-cmake $@
    C c cmake -C example/libexpat-git-subpath-cmake $@
    ;;
*)
    echo "Usage: $0 {autotools|cmake|http|subpath|all}"
    exit 1
    ;;
esac
