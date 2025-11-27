#!/bin/bash

# libvips Android 编译脚本 (使用 Workspace)
# 
# 使用方法:
#   ./build-android-with-workspace.sh [选项]
#
# 选项:
#   --target <lib>  只编译指定库及其依赖 (默认: 编译所有)
#   --clean         清理所有构建产物后重新编译
#   --skip-compile  跳过编译
#   --help          显示帮助信息

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# 默认参数
TARGET=""
CLEAN=false
SKIP_COMPILE=false
INSTALL_PREFIX="$SCRIPT_DIR/installed"
OUTPUT_DIR="$SCRIPT_DIR/output"

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --target)
            TARGET="$2"
            shift 2
            ;;
        --clean)
            CLEAN=true
            shift
            ;;
        --skip-compile)
            SKIP_COMPILE=true
            shift
            ;;
        --help)
            echo "libvips Android 编译脚本 (使用 Workspace)"
            echo ""
            echo "使用方法:"
            echo "  ./build-android-with-workspace.sh [选项]"
            echo ""
            echo "选项:"
            echo "  --target <lib>  只编译指定库及其依赖"
            echo "  --clean         清理所有构建产物后重新编译"
            echo "  --skip-compile  跳过编译"
            echo "  --help          显示帮助信息"
            echo ""
            echo "示例:"
            echo "  ./build-android-with-workspace.sh                    # 编译所有库"
            echo "  ./build-android-with-workspace.sh --target libvips   # 只编译 libvips 及其依赖"
            echo "  ./build-android-with-workspace.sh --clean            # 清理后重新编译"
            exit 0
            ;;
        *)
            echo "未知选项: $1"
            exit 1
            ;;
    esac
done

# 切换到项目根目录
cd "$PROJECT_ROOT"

# 清理
if [ "$CLEAN" = true ]; then
    echo ">>> 清理构建产物..."
    dart run bin/compile.dart clean -C example/libvips -i
    echo "清理完成"
fi

echo "============================================================"
echo "libvips Android 编译 (Workspace 模式)"
echo "============================================================"
echo "Workspace: $SCRIPT_DIR"
echo "安装目录: $INSTALL_PREFIX"
echo "输出目录: $OUTPUT_DIR"
if [ -n "$TARGET" ]; then
    echo "目标库: $TARGET"
else
    echo "目标库: 全部"
fi
echo "============================================================"
echo ""

# 1. 编译 (如果没有跳过)
if [ "$SKIP_COMPILE" = false ]; then
    # 构建 workspace 命令参数
    WORKSPACE_ARGS="workspace -C example/libvips -i --no-ios --android"
    WORKSPACE_ARGS="$WORKSPACE_ARGS -p $INSTALL_PREFIX -d $INSTALL_PREFIX"
    
    if [ -n "$TARGET" ]; then
        WORKSPACE_ARGS="$WORKSPACE_ARGS --target $TARGET"
    fi
    
    echo ">>> 使用 Workspace 编译..."
    dart run bin/compile.dart $WORKSPACE_ARGS
fi

echo ""
echo "============================================================"
echo "编译完成!"
echo ""
echo "安装目录:"
echo "  $INSTALL_PREFIX/android/"
echo "============================================================"
