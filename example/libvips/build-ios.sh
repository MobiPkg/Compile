#!/bin/bash
# libvips iOS 编译脚本
# 使用方法: ./build-ios.sh [--prefix=/path/to/install]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# 默认安装路径
PREFIX="${PREFIX:-$SCRIPT_DIR/install}"

# 解析参数
for arg in "$@"; do
  case $arg in
    --prefix=*)
      PREFIX="${arg#*=}"
      shift
      ;;
  esac
done

echo "=========================================="
echo "libvips iOS 编译"
echo "安装路径: $PREFIX"
echo "=========================================="

# 编译函数
compile_lib() {
  local lib_path="$1"
  local lib_name="$(basename "$lib_path")"
  
  echo ""
  echo ">>> 编译 $lib_name for iOS..."
  echo ""
  
  cd "$PROJECT_ROOT"
  dart run bin/compile.dart \
    --lib "$lib_path" \
    --ios \
    --prefix "$PREFIX"
}

# 依赖编译顺序 (按依赖关系排序)
DEPS=(
  "deps/zlib"
  "deps/libffi"
  "deps/pcre2"
  "deps/expat"
  "deps/glib"
)

# 编译所有依赖
for dep in "${DEPS[@]}"; do
  compile_lib "$SCRIPT_DIR/$dep"
done

# 编译 libvips
compile_lib "$SCRIPT_DIR/libvips"

echo ""
echo "=========================================="
echo "编译完成!"
echo "安装路径: $PREFIX"
echo "=========================================="
