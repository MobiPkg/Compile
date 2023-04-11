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
    C c cmake -C example/git-cmake/zlib $@
    ;;
http)
    C c cmake -C example/zlib-http-cmake $@
    ;;
subpath)
    C c cmake -C example/git-cmake/libexpat-subpath $@
    ;;
meson)
    # C c meson -C example/git-meson/glib $@
    C c meson -C example/git-meson/mesa $@
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
