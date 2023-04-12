#!/usr/bin/env zsh

alias C="dart bin/compile.dart"

set -e

TYPE=$1

# remove parmeters $1
shift 1

case $TYPE in
autotools | at)
    C c autotools -C example/git-autotools/libffi $@
    ;;
cmake | cm)
    C c cmake -C example/git-cmake/zlib $@
    ;;
http)
    C c cmake -C example/http-cmake/zlib $@
    ;;
subpath)
    C c cmake -C example/git-cmake/libexpat-subpath $@
    ;;
meson)
    # C c meson -C example/git-meson/glib $@
    # C c meson -C example/git-meson/mesa $@
    ;;
all)
    $0 autotools $@
    $0 cmake $@
    $0 http $@
    $0 subpath $@
    $0 meson $@
    ;;
*)
    echo "Usage: $0 {autotools|cmake|http|subpath|all}"
    exit 1
    ;;
esac
