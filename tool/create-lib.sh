path=$(dirname "$0")
libname="$1"
lib_path="$path/../logs/$libname"

if [ -z "$libname" ]; then
    echo "Usage: $0 <libname>"
    exit 1
fi

if [ -d "$lib_path" ]; then
    echo "Library $libname already exists"
    exit 1
fi

dart "$path/../bin/compile.dart" template auto -C "$lib_path"