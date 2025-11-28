#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0); pwd)

PROJECT_DIR=$(realpath $SCRIPT_DIR/../..)

cd $PROJECT_DIR

LIB_VIPS_DIR=$PROJECT_DIR/example/libvips

TARGET_DIR=$LIB_VIPS_DIR/install/android

if [ -d "$TARGET_DIR" ]; then
    rm -rf $TARGET_DIR
fi

mkdir -p $TARGET_DIR

# Skip x86/x86_64 due to libffi assembly compatibility issues with Android NDK
# Only compile ARM architectures: arm64-v8a, armeabi-v7a
dart run bin/compile.dart workspace -C $LIB_VIPS_DIR \
    --no-ios --android \
    --android-cpu arm64-v8a,armeabi-v7a \
    --install-prefix $TARGET_DIR \
    --dependency-prefix $TARGET_DIR \
    --target libvips 2>&1 | tee $TARGET_DIR/compile-android.log