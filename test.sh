#!/usr/bin/env zsh

alias C="dart bin/compile.dart"

set -e

TYPE=$1

# remove parmeters $1
shift 1

case $TYPE in
autotools | at)
    C lib -C example/git-autotools/libffi $@
    ;;
cmake | cm)
    C lib -C example/git-cmake/zlib $@
    ;;
http)
    C lib -C example/http-cmake/zlib $@
    ;;
subpath)
    C lib -C example/git-cmake/libexpat-subpath $@
    ;;
meson)
    C lib meson -C example/git-meson/glib $@
    ;;
project)
    C project -C example-project/glib -o example-project/project-opt.yml $@
    ;;
create)
    C template auto -C logs/libs/$@
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
