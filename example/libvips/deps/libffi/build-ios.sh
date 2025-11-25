#!/bin/bash
# libffi iOS 交叉编译脚本
# libffi 使用特殊的 builddir 机制，在源目录中创建以 host 命名的子目录
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/source/libffi"
INSTALL_PREFIX="${1:-$SCRIPT_DIR/../../install}"

# 下载源码（如果不存在）
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Downloading libffi..."
    git clone --depth 1 --branch v3.5.2 https://github.com/libffi/libffi.git "$SOURCE_DIR"
fi

# 确保 autogen 已运行
if [ ! -f "$SOURCE_DIR/configure" ]; then
    echo "Running autogen.sh..."
    cd "$SOURCE_DIR"
    ./autogen.sh
fi

build_arch() {
    local ARCH=$1
    local SDK=$2
    local HOST=$3
    local MIN_VERSION=$4
    local PLATFORM=$5  # iphoneos 或 iphonesimulator
    
    echo "=========================================="
    echo "Building libffi for $ARCH ($SDK)"
    echo "=========================================="
    
    # 根据平台确定安装目录
    local INSTALL_SUBDIR="$ARCH"
    if [ "$PLATFORM" = "simulator" ]; then
        INSTALL_SUBDIR="${ARCH}-simulator"
    fi
    local ARCH_INSTALL="$INSTALL_PREFIX/ios/$INSTALL_SUBDIR"
    
    # libffi 会在源目录中创建以 host 命名的 build 目录
    # 为模拟器使用不同的目录名
    local BUILD_DIR="$SOURCE_DIR/${HOST}-${SDK}"
    rm -rf "$BUILD_DIR"
    
    cd "$SOURCE_DIR"
    
    # 获取 SDK 路径
    local SDK_PATH=$(xcrun --sdk $SDK --show-sdk-path)
    
    # 设置编译器
    export CC="xcrun -sdk $SDK clang"
    export CXX="xcrun -sdk $SDK clang++"
    export AR="xcrun -sdk $SDK ar"
    export RANLIB="xcrun -sdk $SDK ranlib"
    export STRIP="xcrun -sdk $SDK strip"
    
    # 设置 flags - 模拟器和真机使用不同的 min version flag
    local MIN_VERSION_FLAG="-miphoneos-version-min=$MIN_VERSION"
    if [ "$SDK" = "iphonesimulator" ]; then
        MIN_VERSION_FLAG="-mios-simulator-version-min=$MIN_VERSION"
    fi
    export CFLAGS="-arch $ARCH -isysroot $SDK_PATH $MIN_VERSION_FLAG -fPIC -O2"
    export CXXFLAGS="$CFLAGS"
    export LDFLAGS="-arch $ARCH -isysroot $SDK_PATH $MIN_VERSION_FLAG"
    
    # 配置 - libffi 会自动创建以 host 命名的 build 子目录
    # 但我们需要区分真机和模拟器，所以先配置，然后重命名目录
    ./configure \
        --host=$HOST \
        --prefix="$ARCH_INSTALL" \
        --disable-docs \
        --disable-multi-os-directory \
        --enable-static \
        --disable-shared
    
    # libffi 创建的目录是 $HOST，我们需要重命名以区分真机和模拟器
    local LIBFFI_BUILD_DIR="$SOURCE_DIR/$HOST"
    if [ "$LIBFFI_BUILD_DIR" != "$BUILD_DIR" ] && [ -d "$LIBFFI_BUILD_DIR" ]; then
        mv "$LIBFFI_BUILD_DIR" "$BUILD_DIR"
    fi
    
    # 编译和安装 (在 build 子目录中)
    cd "$BUILD_DIR"
    
    # Workaround: 手动生成 fficonfig.h (libffi autotools bug)
    if [ ! -f fficonfig.h ] || [ ! -s fficonfig.h ]; then
        echo "Generating fficonfig.h manually..."
        # 从 config.log 提取定义
        cat > fficonfig.h << 'FFICONFIG_EOF'
/* fficonfig.h - Generated for iOS cross-compilation */

#define STDC_HEADERS 1
#define HAVE_ALLOCA_H 1
#define HAVE_MEMCPY 1
#define HAVE_INTTYPES_H 1
#define HAVE_STDINT_H 1
#define HAVE_STDLIB_H 1
#define HAVE_STRING_H 1
#define HAVE_SYS_STAT_H 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_UNISTD_H 1
#define HAVE_DLFCN_H 1
#define SIZEOF_SIZE_T 8
#define SIZEOF_DOUBLE 8
#define SIZEOF_LONG_DOUBLE 8
#define HAVE_LONG_DOUBLE 1
#define HAVE_AS_CFI_PSEUDO_OP 1
#define HAVE_HIDDEN_VISIBILITY_ATTRIBUTE 1
#define FFI_EXEC_TRAMPOLINE_TABLE 1
#define EH_FRAME_FLAGS "aw"

/* Symbol visibility - different for ASM and C */
#ifdef LIBFFI_ASM
#ifdef __APPLE__
#define FFI_HIDDEN(name) .private_extern name
#else
#define FFI_HIDDEN(name) .hidden name
#endif
#else
#define FFI_HIDDEN __attribute__ ((visibility ("hidden")))
#endif

FFICONFIG_EOF
        echo "fficonfig.h generated"
    fi
    
    make -j$(sysctl -n hw.ncpu)
    make install
    
    echo "Installed to $ARCH_INSTALL"
}

# 编译 arm64 (真机)
build_arch "arm64" "iphoneos" "aarch64-apple-darwin" "12.0" "device"

# 编译 arm64 模拟器 (Apple Silicon Mac)
build_arch "arm64" "iphonesimulator" "aarch64-apple-darwin" "12.0" "simulator"

# x86_64 模拟器编译有汇编兼容性问题，暂时跳过
# build_arch "x86_64" "iphonesimulator" "x86_64-apple-darwin" "12.0" "simulator"
echo "Note: x86_64 simulator build skipped due to assembly compatibility issues"

# 复制到 universal 目录 (仅 arm64)
echo "=========================================="
echo "Copying to universal directory"
echo "=========================================="

UNIVERSAL_DIR="$INSTALL_PREFIX/ios/universal"
mkdir -p "$UNIVERSAL_DIR/lib"
cp -r "$INSTALL_PREFIX/ios/arm64/include" "$UNIVERSAL_DIR/" 2>/dev/null || true
cp -r "$INSTALL_PREFIX/ios/arm64/lib/pkgconfig" "$UNIVERSAL_DIR/lib/" 2>/dev/null || true
cp "$INSTALL_PREFIX/ios/arm64/lib/libffi.a" "$UNIVERSAL_DIR/lib/"

echo "=========================================="
echo "libffi iOS build complete!"
echo "Library: $UNIVERSAL_DIR/lib/libffi.a"
echo "=========================================="
