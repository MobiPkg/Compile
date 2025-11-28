#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0); pwd)

PROJECT_DIR=$(realpath $SCRIPT_DIR/../..)

cd $PROJECT_DIR

LIB_VIPS_DIR=$PROJECT_DIR/example/libvips

TARGET_DIR=$LIB_VIPS_DIR/install/ios

if [ -d "$TARGET_DIR" ]; then
    rm -rf $TARGET_DIR
fi

mkdir -p $TARGET_DIR

dart run bin/compile.dart workspace -C $LIB_VIPS_DIR \
    --ios --no-android \
    --install-prefix $TARGET_DIR \
    --dependency-prefix $TARGET_DIR \
    --target libvips 2>&1 | tee $TARGET_DIR/compile-ios.log