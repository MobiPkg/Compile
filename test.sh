#!/usr/bin/env zsh

alias C="dart bin/compile.dart"

set -e

TYPE=$1

# remove parmeters $1
shift 1

case $TYPE in
autotools | at)
    ## Compile autotools example (libffi)
    C c autotools -C example/libffi-git $@
    ;;
cmake | cm)
    ## Compile cmake example (zlib)
    C c cmake -C example/zlib-git $@
    ;;
http)
    C c cmake -C example/zlib-http $@
    ;;
subpath)
    C c cmake -C example/libexpat-subpath $@
    ;;
all)
    C c autotools -C example/libffi-git $@
    C c cmake -C example/zlib-git $@
    C c cmake -C example/zlib-http $@
    C c cmake -C example/libexpat-subpath $@
    ;;
*)
    echo "Usage: $0 {autotools|cmake|http|subpath|all}"
    exit 1
    ;;
esac
