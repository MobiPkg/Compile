#!/bin/bash
# 创建 libvips XCFramework
# 用法: ./create-xcframework.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$SCRIPT_DIR/install"
OUTPUT_DIR="$SCRIPT_DIR/output"

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 核心库列表（始终包含）
CORE_LIBS=(
    "libvips"
    "libglib-2.0"
    "libgio-2.0"
    "libgobject-2.0"
    "libgmodule-2.0"
    "libgthread-2.0"
    "libffi"
    "libpcre2-8"
    "libintl"
    "libexpat"
    "libz"
)

# 可选库列表（根据编译配置自动检测）
OPTIONAL_LIBS=(
    # 常用图像格式
    "libjpeg"
    "libpng16"
    "libwebp"
    "libwebpmux"
    "libwebpdemux"
    "libsharpyuv"
    # 其他图像格式
    "libtiff"
    "libheif"
    "libde265"
    "libx265"
    "libavif"
    "libaom"
    "libjxl"
    "libopenjp2"
    "libOpenEXR"
    "libcfitsio"
    "libnifti"
    "libmatio"
    "libopenslide"
    "libcgif"
    "libnsgif"
    # 功能模块
    "libexif"
    "liblcms2"
    "libfftw3"
    "liborc"
    "libhwy"
    "libimagequant"
    "libarchive"
)

# 构建最终库列表
LIBS=("${CORE_LIBS[@]}")
for lib in "${OPTIONAL_LIBS[@]}"; do
    # 检查库是否存在于 arm64 或 arm64-simulator 目录
    if [ -f "$INSTALL_DIR/ios/arm64/lib/${lib}.a" ] || \
       [ -f "$INSTALL_DIR/ios/arm64-simulator/lib/${lib}.a" ]; then
        LIBS+=("$lib")
        echo "检测到可选库: $lib"
    fi
done

echo "=========================================="
echo "创建 libvips XCFramework"
echo "=========================================="

# 检查 arm64 是否存在
if [ ! -d "$INSTALL_DIR/ios/arm64" ]; then
    echo "错误: arm64 编译结果不存在"
    echo "请先运行编译脚本"
    exit 1
fi

# 合并静态库函数
merge_libs() {
    local arch_dir="$1"
    local output_lib="$2"
    local arch_name="$3"
    
    echo "合并 $arch_name 静态库..."
    
    local all_libs=""
    for lib in "${LIBS[@]}"; do
        local lib_path="$arch_dir/lib/${lib}.a"
        if [ -f "$lib_path" ]; then
            all_libs="$all_libs $lib_path"
            echo "  添加: $lib"
        else
            echo "  跳过: $lib (不存在)"
        fi
    done
    
    libtool -static -o "$output_lib" $all_libs 2>/dev/null
    echo "合并完成: $output_lib"
}

# 合并 arm64 真机库
MERGED_ARM64="$OUTPUT_DIR/libvips-arm64.a"
merge_libs "$INSTALL_DIR/ios/arm64" "$MERGED_ARM64" "arm64"

# 检查是否有 arm64 模拟器
HAS_SIMULATOR=false
if [ -d "$INSTALL_DIR/ios/arm64-simulator" ] && [ -f "$INSTALL_DIR/ios/arm64-simulator/lib/libvips.a" ]; then
    HAS_SIMULATOR=true
    MERGED_SIM="$OUTPUT_DIR/libvips-arm64-simulator.a"
    merge_libs "$INSTALL_DIR/ios/arm64-simulator" "$MERGED_SIM" "arm64-simulator"
fi

# 创建 XCFramework
XCFRAMEWORK_DIR="$OUTPUT_DIR/libvips.xcframework"
rm -rf "$XCFRAMEWORK_DIR"

if [ "$HAS_SIMULATOR" = true ]; then
    echo ""
    echo "创建包含真机和模拟器的 XCFramework..."
    
    mkdir -p "$XCFRAMEWORK_DIR/ios-arm64"
    mkdir -p "$XCFRAMEWORK_DIR/ios-arm64-simulator"
    
    # 复制真机库和头文件
    cp "$MERGED_ARM64" "$XCFRAMEWORK_DIR/ios-arm64/libvips.a"
    mkdir -p "$XCFRAMEWORK_DIR/ios-arm64/Headers"
    # 复制所有头文件（vips, glib, gio, gobject, ffi 等）
    cp -r "$INSTALL_DIR/ios/arm64/include/"* "$XCFRAMEWORK_DIR/ios-arm64/Headers/"
    # 复制 glibconfig.h（位于 lib/glib-2.0/include/）
    if [ -d "$INSTALL_DIR/ios/arm64/lib/glib-2.0/include" ]; then
        cp -r "$INSTALL_DIR/ios/arm64/lib/glib-2.0/include/"* "$XCFRAMEWORK_DIR/ios-arm64/Headers/glib-2.0/"
    fi
    
    # 复制模拟器库和头文件
    cp "$MERGED_SIM" "$XCFRAMEWORK_DIR/ios-arm64-simulator/libvips.a"
    mkdir -p "$XCFRAMEWORK_DIR/ios-arm64-simulator/Headers"
    # 复制所有头文件
    cp -r "$INSTALL_DIR/ios/arm64-simulator/include/"* "$XCFRAMEWORK_DIR/ios-arm64-simulator/Headers/"
    # 复制 glibconfig.h
    if [ -d "$INSTALL_DIR/ios/arm64-simulator/lib/glib-2.0/include" ]; then
        cp -r "$INSTALL_DIR/ios/arm64-simulator/lib/glib-2.0/include/"* "$XCFRAMEWORK_DIR/ios-arm64-simulator/Headers/glib-2.0/"
    fi
    
    # 创建 Info.plist (包含真机和模拟器)
    cat > "$XCFRAMEWORK_DIR/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>AvailableLibraries</key>
    <array>
        <dict>
            <key>HeadersPath</key>
            <string>Headers</string>
            <key>LibraryIdentifier</key>
            <string>ios-arm64</string>
            <key>LibraryPath</key>
            <string>libvips.a</string>
            <key>SupportedArchitectures</key>
            <array>
                <string>arm64</string>
            </array>
            <key>SupportedPlatform</key>
            <string>ios</string>
        </dict>
        <dict>
            <key>HeadersPath</key>
            <string>Headers</string>
            <key>LibraryIdentifier</key>
            <string>ios-arm64-simulator</string>
            <key>LibraryPath</key>
            <string>libvips.a</string>
            <key>SupportedArchitectures</key>
            <array>
                <string>arm64</string>
            </array>
            <key>SupportedPlatform</key>
            <string>ios</string>
            <key>SupportedPlatformVariant</key>
            <string>simulator</string>
        </dict>
    </array>
    <key>CFBundlePackageType</key>
    <string>XFWK</string>
    <key>XCFrameworkFormatVersion</key>
    <string>1.0</string>
</dict>
</plist>
EOF
else
    echo ""
    echo "创建仅包含真机的 XCFramework..."
    
    mkdir -p "$XCFRAMEWORK_DIR/ios-arm64"
    cp "$MERGED_ARM64" "$XCFRAMEWORK_DIR/ios-arm64/libvips.a"
    mkdir -p "$XCFRAMEWORK_DIR/ios-arm64/Headers"
    # 复制所有头文件
    cp -r "$INSTALL_DIR/ios/arm64/include/"* "$XCFRAMEWORK_DIR/ios-arm64/Headers/"
    # 复制 glibconfig.h
    if [ -d "$INSTALL_DIR/ios/arm64/lib/glib-2.0/include" ]; then
        cp -r "$INSTALL_DIR/ios/arm64/lib/glib-2.0/include/"* "$XCFRAMEWORK_DIR/ios-arm64/Headers/glib-2.0/"
    fi
    
    # 创建 Info.plist (仅真机)
    cat > "$XCFRAMEWORK_DIR/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>AvailableLibraries</key>
    <array>
        <dict>
            <key>HeadersPath</key>
            <string>Headers</string>
            <key>LibraryIdentifier</key>
            <string>ios-arm64</string>
            <key>LibraryPath</key>
            <string>libvips.a</string>
            <key>SupportedArchitectures</key>
            <array>
                <string>arm64</string>
            </array>
            <key>SupportedPlatform</key>
            <string>ios</string>
        </dict>
    </array>
    <key>CFBundlePackageType</key>
    <string>XFWK</string>
    <key>XCFrameworkFormatVersion</key>
    <string>1.0</string>
</dict>
</plist>
EOF
fi

echo ""
echo "=========================================="
echo "XCFramework 创建完成!"
echo "输出: $XCFRAMEWORK_DIR"
echo ""
echo "包含架构:"
echo "  - ios-arm64 (真机)"
if [ "$HAS_SIMULATOR" = true ]; then
    echo "  - ios-arm64-simulator (模拟器)"
fi
echo ""
echo "使用方法:"
echo "1. 将 libvips.xcframework 拖入 Xcode 项目"
echo "2. 在 Build Settings 中添加 Header Search Paths (递归)"
echo "3. 链接系统库: libiconv.tbd, libresolv.tbd"
echo "4. 链接系统框架: Foundation, CoreFoundation"
echo "=========================================="

# 显示大小信息
echo ""
echo "文件大小:"
du -h "$XCFRAMEWORK_DIR"/*/libvips.a
