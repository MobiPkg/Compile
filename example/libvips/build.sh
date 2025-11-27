#!/bin/bash
# libvips iOS 编译脚本
# 通过修改下方配置来选择要编译的模块
#
# 用法: ./build.sh [arm64|arm64-simulator|all]
# 默认编译所有架构

set -e

#=============================================================================
# 模块配置 - 修改 true/false 来启用/禁用模块
#=============================================================================

#-----------------------------------------------------------------------------
# 常用图像格式（推荐启用）
#-----------------------------------------------------------------------------
ENABLE_JPEG=true       # JPEG 支持 (libjpeg-turbo) - 照片必备
ENABLE_PNG=true        # PNG 支持 (libpng) - 截图、图标
ENABLE_WEBP=true       # WebP 支持 (libwebp) - 现代 Web 格式

#-----------------------------------------------------------------------------
# 其他图像格式（按需启用）
#-----------------------------------------------------------------------------
ENABLE_GIF=false       # GIF 支持 (cgif, libnsgif) - 动画图像
ENABLE_TIFF=false      # TIFF 支持 (libtiff) - 专业图像
ENABLE_HEIF=false      # HEIF/HEIC 支持 (libheif, x265) - Apple 格式
ENABLE_AVIF=false      # AVIF 支持 (libavif, aom) - 新一代格式
ENABLE_JPEG_XL=false   # JPEG XL 支持 (libjxl) - 新一代 JPEG
ENABLE_OPENJPEG=false  # JPEG 2000 支持 (openjpeg)
ENABLE_OPENEXR=false   # OpenEXR 支持 - HDR 图像
ENABLE_FITS=false      # FITS 支持 (cfitsio) - 天文图像
ENABLE_NIFTI=false     # NIfTI 支持 - 医学图像
ENABLE_MATIO=false     # MATLAB 支持 (matio)
ENABLE_OPENSLIDE=false # OpenSlide 支持 - 数字病理

#-----------------------------------------------------------------------------
# 功能模块（按需启用）
#-----------------------------------------------------------------------------
ENABLE_EXIF=false      # EXIF 元数据 (libexif)
ENABLE_LCMS=false      # 色彩管理 (lcms2) - ICC 配置文件
ENABLE_FFTW=false      # FFT 支持 (fftw3) - 频域处理
ENABLE_ORC=false       # ORC 支持 - SIMD 优化
ENABLE_HIGHWAY=false   # Highway 支持 - SIMD 优化
ENABLE_IMAGEQUANT=false # 图像量化 (libimagequant) - PNG 优化
ENABLE_QUANTIZR=false  # Quantizr 支持 - 颜色量化
ENABLE_ARCHIVE=false   # Archive 支持 (libarchive) - 压缩文件

#-----------------------------------------------------------------------------
# 文本/矢量（iOS 不推荐，依赖复杂）
#-----------------------------------------------------------------------------
ENABLE_FONTCONFIG=false # 字体配置 (fontconfig)
ENABLE_PANGOCAIRO=false # Pango/Cairo 支持 - 文本渲染
ENABLE_RSVG=false      # SVG 支持 (librsvg) - 矢量图形
ENABLE_POPPLER=false   # PDF 支持 (poppler)
ENABLE_PDFIUM=false    # PDF 支持 (pdfium)
ENABLE_MAGICK=false    # ImageMagick 支持

#=============================================================================
# 架构配置
#=============================================================================

# 默认编译架构
BUILD_ARM64=true           # iPhone/iPad 真机
BUILD_ARM64_SIMULATOR=true # Apple Silicon 模拟器

#=============================================================================
# 以下为脚本逻辑，一般不需要修改
#=============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
INSTALL_PREFIX="$SCRIPT_DIR/install"
LOG_DIR="$SCRIPT_DIR/logs"

# 解析命令行参数
case "${1:-all}" in
    arm64)
        BUILD_ARM64=true
        BUILD_ARM64_SIMULATOR=false
        ;;
    arm64-simulator)
        BUILD_ARM64=false
        BUILD_ARM64_SIMULATOR=true
        ;;
    all)
        BUILD_ARM64=true
        BUILD_ARM64_SIMULATOR=true
        ;;
    *)
        echo "用法: $0 [arm64|arm64-simulator|all]"
        exit 1
        ;;
esac

# 构建 CPU 参数
CPU_ARGS=""
if [ "$BUILD_ARM64" = true ]; then
    CPU_ARGS="$CPU_ARGS --ios-cpu arm64"
fi
if [ "$BUILD_ARM64_SIMULATOR" = true ]; then
    CPU_ARGS="$CPU_ARGS --ios-cpu arm64-simulator"
fi

COMMON_ARGS="--no-android --no-harmony --ios $CPU_ARGS --install-prefix $INSTALL_PREFIX --dependency-prefix $INSTALL_PREFIX --log-dir $LOG_DIR"

echo "=========================================="
echo "libvips iOS 编译脚本"
echo "=========================================="
echo ""
echo "编译架构:"
[ "$BUILD_ARM64" = true ] && echo "  - arm64 (真机)"
[ "$BUILD_ARM64_SIMULATOR" = true ] && echo "  - arm64-simulator (模拟器)"
echo ""
echo "启用的模块:"
echo "  图像格式:"
[ "$ENABLE_JPEG" = true ] && echo "    - JPEG (libjpeg-turbo)"
[ "$ENABLE_PNG" = true ] && echo "    - PNG (libpng)"
[ "$ENABLE_WEBP" = true ] && echo "    - WebP (libwebp)"
[ "$ENABLE_GIF" = true ] && echo "    - GIF (cgif)"
[ "$ENABLE_TIFF" = true ] && echo "    - TIFF (libtiff)"
[ "$ENABLE_HEIF" = true ] && echo "    - HEIF (libheif)"
[ "$ENABLE_AVIF" = true ] && echo "    - AVIF (libavif)"
[ "$ENABLE_JPEG_XL" = true ] && echo "    - JPEG XL (libjxl)"
[ "$ENABLE_OPENJPEG" = true ] && echo "    - JPEG 2000 (openjpeg)"
[ "$ENABLE_OPENEXR" = true ] && echo "    - OpenEXR"
[ "$ENABLE_FITS" = true ] && echo "    - FITS (cfitsio)"
[ "$ENABLE_NIFTI" = true ] && echo "    - NIfTI"
[ "$ENABLE_MATIO" = true ] && echo "    - MATLAB (matio)"
[ "$ENABLE_OPENSLIDE" = true ] && echo "    - OpenSlide"
echo "  功能模块:"
[ "$ENABLE_EXIF" = true ] && echo "    - EXIF (libexif)"
[ "$ENABLE_LCMS" = true ] && echo "    - LCMS (lcms2)"
[ "$ENABLE_FFTW" = true ] && echo "    - FFTW"
[ "$ENABLE_ORC" = true ] && echo "    - ORC"
[ "$ENABLE_HIGHWAY" = true ] && echo "    - Highway"
[ "$ENABLE_IMAGEQUANT" = true ] && echo "    - ImageQuant"
[ "$ENABLE_QUANTIZR" = true ] && echo "    - Quantizr"
[ "$ENABLE_ARCHIVE" = true ] && echo "    - Archive"
echo ""
echo "=========================================="

cd "$PROJECT_ROOT"

# 编译函数
compile_lib() {
    local lib_path="$1"
    local lib_name="$2"
    
    if [ -d "$lib_path" ]; then
        echo ""
        echo ">>> 编译 $lib_name..."
        dart run bin/compile.dart lib -C "$lib_path" $COMMON_ARGS
    else
        echo "警告: $lib_path 不存在，跳过 $lib_name"
    fi
}

# 1. 编译 libffi (特殊处理)
echo ""
echo ">>> 编译 libffi..."
if [ "$BUILD_ARM64" = true ]; then
    "$SCRIPT_DIR/deps/libffi/build-ios.sh" "$INSTALL_PREFIX" arm64
fi
if [ "$BUILD_ARM64_SIMULATOR" = true ]; then
    "$SCRIPT_DIR/deps/libffi/build-ios.sh" "$INSTALL_PREFIX" arm64-simulator
fi

# 2. 编译核心依赖
compile_lib "example/libvips/deps/zlib" "zlib"
compile_lib "example/libvips/deps/pcre2" "pcre2"
compile_lib "example/libvips/deps/expat" "expat"
compile_lib "example/libvips/deps/glib" "glib"

# 3. 编译可选模块
if [ "$ENABLE_JPEG" = true ]; then
    compile_lib "example/libvips/deps/libjpeg-turbo" "libjpeg-turbo"
fi

if [ "$ENABLE_PNG" = true ]; then
    compile_lib "example/libvips/deps/libpng" "libpng"
fi

if [ "$ENABLE_WEBP" = true ]; then
    compile_lib "example/libvips/deps/libwebp" "libwebp"
fi

# 4. 生成 libvips 的 meson 选项
generate_vips_options() {
    local options=""
    
    # JPEG
    if [ "$ENABLE_JPEG" = true ]; then
        options="$options -Djpeg=enabled"
    else
        options="$options -Djpeg=disabled"
    fi
    
    # PNG
    if [ "$ENABLE_PNG" = true ]; then
        options="$options -Dpng=enabled"
    else
        options="$options -Dpng=disabled"
    fi
    
    # WebP
    if [ "$ENABLE_WEBP" = true ]; then
        options="$options -Dspng=disabled -Dwebp=enabled"
    else
        options="$options -Dspng=disabled -Dwebp=disabled"
    fi
    
    # GIF
    if [ "$ENABLE_GIF" = true ]; then
        options="$options -Dcgif=enabled -Dnsgif=enabled"
    else
        options="$options -Dcgif=disabled -Dnsgif=disabled"
    fi
    
    # TIFF
    if [ "$ENABLE_TIFF" = true ]; then
        options="$options -Dtiff=enabled"
    else
        options="$options -Dtiff=disabled"
    fi
    
    # HEIF
    if [ "$ENABLE_HEIF" = true ]; then
        options="$options -Dheif=enabled"
    else
        options="$options -Dheif=disabled"
    fi
    
    # EXIF
    if [ "$ENABLE_EXIF" = true ]; then
        options="$options -Dexif=enabled"
    else
        options="$options -Dexif=disabled"
    fi
    
    # LCMS
    if [ "$ENABLE_LCMS" = true ]; then
        options="$options -Dlcms=enabled"
    else
        options="$options -Dlcms=disabled"
    fi
    
    echo "$options"
}

# 5. 生成 libvips/lib.yaml
echo ""
echo ">>> 生成 libvips 配置..."

# 辅助函数：将 true/false 转换为 enabled/disabled
opt() { [ "$1" = true ] && echo "enabled" || echo "disabled"; }
# 辅助函数：布尔类型选项
bool() { [ "$1" = true ] && echo "true" || echo "false"; }

cat > "$SCRIPT_DIR/libvips/lib.yaml" << EOF
name: libvips
type: meson
source:
  git:
    url: https://github.com/libvips/libvips.git
    ref: v8.16.0
license: LICENSE

deps:
  - glib
  - expat
  - zlib
  - libjpeg-turbo
  - libpng
  - libwebp

flags:
  # iOS 支持 posix_memalign，但 meson 交叉编译检测失败，需要手动定义
  c: -fPIC -O2 -DHAVE_POSIX_MEMALIGN=1
  cxx: -fPIC -O2 -DHAVE_POSIX_MEMALIGN=1
  cpp: ""
  # 链接 libwebpmux/libwebpdemux (WebP 动画支持), libsharpyuv (libwebp 的私有依赖) 和 zlib (libpng 的依赖)
  ld: -lwebpmux -lwebpdemux -lsharpyuv -lz

options:
  # 禁用不需要的功能以减少依赖
  - -Dgtk_doc=false
  - -Dintrospection=disabled
  - -Dvapi=false
  - -Dmodules=disabled
  - -Dexamples=false
  - -Dcplusplus=false
  
  # 常用图像格式
  - -Djpeg=$(opt $ENABLE_JPEG)
  - -Dpng=$(opt $ENABLE_PNG)
  - -Dwebp=$(opt $ENABLE_WEBP)
  
  # 其他图像格式
  - -Dcgif=$(opt $ENABLE_GIF)
  - -Dnsgif=$(bool $ENABLE_GIF)
  - -Dtiff=$(opt $ENABLE_TIFF)
  - -Dheif=$(opt $ENABLE_HEIF)
  - -Djpeg-xl=$(opt $ENABLE_JPEG_XL)
  - -Dopenjpeg=$(opt $ENABLE_OPENJPEG)
  - -Dopenexr=$(opt $ENABLE_OPENEXR)
  - -Dcfitsio=$(opt $ENABLE_FITS)
  - -Dnifti=$(opt $ENABLE_NIFTI)
  - -Dmatio=$(opt $ENABLE_MATIO)
  - -Dopenslide=$(opt $ENABLE_OPENSLIDE)
  
  # 功能模块
  - -Dexif=$(opt $ENABLE_EXIF)
  - -Dlcms=$(opt $ENABLE_LCMS)
  - -Dfftw=$(opt $ENABLE_FFTW)
  - -Dorc=$(opt $ENABLE_ORC)
  - -Dhighway=$(opt $ENABLE_HIGHWAY)
  - -Dimagequant=$(opt $ENABLE_IMAGEQUANT)
  - -Dquantizr=$(opt $ENABLE_QUANTIZR)
  - -Darchive=$(opt $ENABLE_ARCHIVE)
  
  # 文本/矢量（iOS 不推荐）
  - -Dfontconfig=$(opt $ENABLE_FONTCONFIG)
  - -Dpangocairo=$(opt $ENABLE_PANGOCAIRO)
  - -Drsvg=$(opt $ENABLE_RSVG)
  - -Dpoppler=$(opt $ENABLE_POPPLER)
  - -Dpdfium=$(opt $ENABLE_PDFIUM)
  - -Dmagick=$(opt $ENABLE_MAGICK)
  
  # 始终禁用
  - -Dspng=disabled
  # zlib 被 libpng 需要，启用它
  - -Dzlib=enabled
EOF

echo "已生成 libvips/lib.yaml"

# 6. 编译 libvips
echo ""
echo ">>> 编译 libvips..."
dart run bin/compile.dart lib -C "example/libvips/libvips" $COMMON_ARGS

# 7. 创建 XCFramework
echo ""
echo ">>> 创建 XCFramework..."
cd "$SCRIPT_DIR"
./create-xcframework.sh

echo ""
echo "=========================================="
echo "编译完成!"
echo "XCFramework: $SCRIPT_DIR/output/libvips.xcframework"
echo ""
echo "编译日志: $LOG_DIR"
echo "  查看所有日志: ls -la $LOG_DIR"
echo "  查看主日志:   cat $LOG_DIR/*-main.log"
echo "=========================================="
