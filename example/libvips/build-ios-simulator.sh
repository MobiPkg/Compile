#!/bin/bash
# libvips iOS arm64 模拟器编译脚本
# 用法: ./build-ios-simulator.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
INSTALL_PREFIX="$SCRIPT_DIR/install"
SIMULATOR_INSTALL="$INSTALL_PREFIX/ios/arm64-simulator"

echo "=========================================="
echo "libvips iOS arm64 模拟器编译"
echo "安装路径: $SIMULATOR_INSTALL"
echo "=========================================="

# SDK 和编译器设置
SDK="iphonesimulator"
SDK_PATH=$(xcrun --sdk $SDK --show-sdk-path)
MIN_VERSION="12.0"
ARCH="arm64"
TARGET="arm64-apple-ios-simulator"

# 设置环境变量
export CC="xcrun -sdk $SDK clang -target $TARGET"
export CXX="xcrun -sdk $SDK clang++ -target $TARGET"
export AR="xcrun -sdk $SDK ar"
export RANLIB="xcrun -sdk $SDK ranlib"
export STRIP="xcrun -sdk $SDK strip"
export CFLAGS="-arch $ARCH -isysroot $SDK_PATH -mios-simulator-version-min=$MIN_VERSION -fPIC -O2"
export CXXFLAGS="$CFLAGS"
export LDFLAGS="-arch $ARCH -isysroot $SDK_PATH"
export PKG_CONFIG_PATH="$SIMULATOR_INSTALL/lib/pkgconfig"

mkdir -p "$SIMULATOR_INSTALL"

# 编译函数 - CMake
compile_cmake() {
    local lib_path="$1"
    local lib_name="$(basename "$lib_path")"
    local source_dir="$lib_path/source/$lib_name"
    local build_dir="$lib_path/build/ios/arm64-simulator"
    
    echo ""
    echo ">>> 编译 $lib_name (CMake) for iOS arm64 模拟器..."
    
    # 检查源码是否存在，如果不存在则下载
    if [ ! -d "$source_dir" ]; then
        cd "$PROJECT_ROOT"
        dart run bin/compile.dart download --lib "$lib_path"
    fi
    
    # 检查是否有 subpath
    local cmake_source="$source_dir"
    if [ -f "$lib_path/lib.yaml" ]; then
        local subpath=$(grep "subpath:" "$lib_path/lib.yaml" | sed 's/.*subpath: *//' | tr -d ' ')
        if [ -n "$subpath" ]; then
            cmake_source="$source_dir/$subpath"
        fi
    fi
    
    echo "  源码目录: $cmake_source"
    
    rm -rf "$build_dir"
    mkdir -p "$build_dir"
    cd "$build_dir"
    
    cmake "$cmake_source" \
        -DCMAKE_INSTALL_PREFIX="$SIMULATOR_INSTALL" \
        -DCMAKE_SYSTEM_NAME=iOS \
        -DCMAKE_OSX_SYSROOT="$SDK_PATH" \
        -DCMAKE_OSX_ARCHITECTURES="$ARCH" \
        -DCMAKE_OSX_DEPLOYMENT_TARGET="$MIN_VERSION" \
        -DCMAKE_C_FLAGS="$CFLAGS" \
        -DCMAKE_CXX_FLAGS="$CXXFLAGS" \
        -DBUILD_SHARED_LIBS=OFF \
        $(grep "^  - -D" "$lib_path/lib.yaml" 2>/dev/null | sed 's/^  - //' || true)
    
    cmake --build . -j$(sysctl -n hw.ncpu)
    cmake --install .
    
    echo ">>> $lib_name 安装完成"
}

# 编译 zlib
compile_cmake "$SCRIPT_DIR/deps/zlib"

# 编译 pcre2
compile_cmake "$SCRIPT_DIR/deps/pcre2"

# 编译 expat
compile_cmake "$SCRIPT_DIR/deps/expat"

# libffi 已经在 build-ios.sh 中编译了 arm64-simulator

# 编译 glib (meson)
echo ""
echo ">>> 编译 glib (Meson) for iOS arm64 模拟器..."

GLIB_SOURCE="$SCRIPT_DIR/deps/glib/source/glib"
GLIB_BUILD="$SCRIPT_DIR/deps/glib/build/ios/arm64-simulator"

# 下载源码 (如果不存在)
if [ ! -d "$GLIB_SOURCE" ]; then
    cd "$PROJECT_ROOT"
    dart run bin/compile.dart download --lib "$SCRIPT_DIR/deps/glib"
fi

rm -rf "$GLIB_BUILD"
mkdir -p "$GLIB_BUILD"

# 创建 meson cross file
cat > "$GLIB_BUILD/cross-file.ini" << EOF
[host_machine]
system = 'ios'
cpu_family = 'aarch64'
cpu = 'aarch64'
endian = 'little'

[properties]
needs_exe_wrapper = true

[binaries]
c = ['xcrun', '-sdk', 'iphonesimulator', 'clang', '-target', 'arm64-apple-ios-simulator']
cpp = ['xcrun', '-sdk', 'iphonesimulator', 'clang++', '-target', 'arm64-apple-ios-simulator']
ar = ['xcrun', '-sdk', 'iphonesimulator', 'ar']
strip = ['xcrun', '-sdk', 'iphonesimulator', 'strip']
pkg-config = '$(which pkg-config)'

[built-in options]
c_args = ['-I$SIMULATOR_INSTALL/include', '-fPIC', '-O2']
cpp_args = ['-I$SIMULATOR_INSTALL/include', '-fPIC', '-O2']
c_link_args = ['-L$SIMULATOR_INSTALL/lib']
cpp_link_args = ['-L$SIMULATOR_INSTALL/lib']
EOF

cd "$GLIB_SOURCE"
meson setup "$GLIB_BUILD" \
    --prefix="$SIMULATOR_INSTALL" \
    --cross-file="$GLIB_BUILD/cross-file.ini" \
    --buildtype=release \
    --default-library=both \
    -Dtests=false \
    -Dglib_debug=disabled \
    -Dintrospection=disabled \
    -Dnls=disabled \
    -Dlibmount=disabled \
    -Dselinux=disabled \
    -Dxattr=false \
    -Dlibelf=disabled \
    -Dglib_assert=false \
    -Dglib_checks=false \
    --wrap-mode=nofallback \
    --force-fallback-for=proxy-libintl,gvdb,pcre2

meson compile -C "$GLIB_BUILD" -j$(sysctl -n hw.ncpu)
meson install -C "$GLIB_BUILD"

echo ">>> glib 安装完成"

# 编译 libvips (meson)
echo ""
echo ">>> 编译 libvips (Meson) for iOS arm64 模拟器..."

VIPS_SOURCE="$SCRIPT_DIR/libvips/source/libvips"
VIPS_BUILD="$SCRIPT_DIR/libvips/build/ios/arm64-simulator"

# 下载源码 (如果不存在)
if [ ! -d "$VIPS_SOURCE" ]; then
    cd "$PROJECT_ROOT"
    dart run bin/compile.dart download --lib "$SCRIPT_DIR/libvips"
fi

rm -rf "$VIPS_BUILD"
mkdir -p "$VIPS_BUILD"

# 创建 meson cross file
cat > "$VIPS_BUILD/cross-file.ini" << EOF
[host_machine]
system = 'ios'
cpu_family = 'aarch64'
cpu = 'aarch64'
endian = 'little'

[properties]
needs_exe_wrapper = true

[binaries]
c = ['xcrun', '-sdk', 'iphonesimulator', 'clang', '-target', 'arm64-apple-ios-simulator']
cpp = ['xcrun', '-sdk', 'iphonesimulator', 'clang++', '-target', 'arm64-apple-ios-simulator']
ar = ['xcrun', '-sdk', 'iphonesimulator', 'ar']
strip = ['xcrun', '-sdk', 'iphonesimulator', 'strip']
pkg-config = '$(which pkg-config)'

[built-in options]
c_args = ['-I$SIMULATOR_INSTALL/include', '-fPIC', '-O2']
cpp_args = ['-I$SIMULATOR_INSTALL/include', '-fPIC', '-O2']
c_link_args = ['-L$SIMULATOR_INSTALL/lib']
cpp_link_args = ['-L$SIMULATOR_INSTALL/lib']
EOF

cd "$VIPS_SOURCE"
meson setup "$VIPS_BUILD" \
    --prefix="$SIMULATOR_INSTALL" \
    --cross-file="$VIPS_BUILD/cross-file.ini" \
    --buildtype=release \
    --default-library=both \
    -Dgtk_doc=false \
    -Dintrospection=disabled \
    -Dvapi=false \
    -Dmodules=disabled \
    -Dexamples=false \
    -Dcplusplus=false \
    -Dcfitsio=disabled \
    -Dcgif=disabled \
    -Dexif=disabled \
    -Dfftw=disabled \
    -Dfontconfig=disabled \
    -Dheif=disabled \
    -Dhighway=disabled \
    -Dimagequant=disabled \
    -Djpeg=disabled \
    -Djpeg-xl=disabled \
    -Dlcms=disabled \
    -Dmagick=disabled \
    -Dmatio=disabled \
    -Dnifti=disabled \
    -Dopenexr=disabled \
    -Dopenjpeg=disabled \
    -Dopenslide=disabled \
    -Dorc=disabled \
    -Dpangocairo=disabled \
    -Dpdfium=disabled \
    -Dpng=disabled \
    -Dpoppler=disabled \
    -Dquantizr=disabled \
    -Drsvg=disabled \
    -Dspng=disabled \
    -Dtiff=disabled \
    -Dwebp=disabled \
    -Dzlib=disabled \
    -Darchive=disabled

meson compile -C "$VIPS_BUILD" -j$(sysctl -n hw.ncpu)
meson install -C "$VIPS_BUILD"

echo ""
echo "=========================================="
echo "libvips iOS arm64 模拟器编译完成!"
echo "安装路径: $SIMULATOR_INSTALL"
echo "=========================================="
