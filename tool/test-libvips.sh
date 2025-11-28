#!/bin/bash

EXE_DIR=/Users/cai/code/mobipkg/Compile

cd $EXE_DIR

LIBVIPS_DIR="example/libvips"
INSTALL_PREFIX="$LIBVIPS_DIR/install"
COMMON="--no-android --no-harmony --install-prefix $INSTALL_PREFIX --dependency-prefix $INSTALL_PREFIX"

# 1. 编译 libffi（需要专用脚本）
$LIBVIPS_DIR/deps/libffi/build-ios.sh $(pwd)/$INSTALL_PREFIX

# 2. 编译所有依赖（真机 + 模拟器）
for lib in zlib pcre2 expat glib; do
  dart run bin/compile.dart lib -C $LIBVIPS_DIR/deps/$lib \
    --ios --ios-cpu arm64 --ios-cpu arm64-simulator $COMMON
done

# 3. 编译 libvips
dart run bin/compile.dart lib -C $LIBVIPS_DIR/libvips \
  --ios --ios-cpu arm64 --ios-cpu arm64-simulator $COMMON

# 4. 创建 XCFramework
cd $LIBVIPS_DIR && ./create-xcframework.sh