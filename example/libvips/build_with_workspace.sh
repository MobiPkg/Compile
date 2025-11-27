#!/bin/bash

# libvips iOS 编译脚本 (使用 Workspace)
# 
# 使用方法:
#   ./build_with_workspace.sh [选项]
#
# 选项:
#   --target <lib>  只编译指定库及其依赖 (默认: 编译所有)
#   --clean         清理所有构建产物后重新编译
#   --help          显示帮助信息

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# 默认参数
TARGET=""
CLEAN=false
IOS_CPUS="arm64"
INSTALL_PREFIX="$SCRIPT_DIR/install"
LOG_DIR="$SCRIPT_DIR/logs"

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
        --help)
            echo "libvips iOS 编译脚本 (使用 Workspace)"
            echo ""
            echo "使用方法:"
            echo "  ./build_with_workspace.sh [选项]"
            echo ""
            echo "选项:"
            echo "  --target <lib>  只编译指定库及其依赖"
            echo "  --clean         清理所有构建产物后重新编译"
            echo "  --help          显示帮助信息"
            echo ""
            echo "示例:"
            echo "  ./build_with_workspace.sh                    # 编译所有库"
            echo "  ./build_with_workspace.sh --target libvips   # 只编译 libvips 及其依赖"
            echo "  ./build_with_workspace.sh --clean            # 清理后重新编译"
            exit 0
            ;;
        *)
            echo "未知选项: $1"
            exit 1
            ;;
    esac
done

# 清理
if [ "$CLEAN" = true ]; then
    echo ">>> 清理构建产物..."
    rm -rf "$SCRIPT_DIR"/*/build
    rm -rf "$SCRIPT_DIR"/*/source
    rm -rf "$INSTALL_PREFIX"
    rm -rf "$LOG_DIR"
    echo "清理完成"
fi

# 切换到项目根目录
cd "$PROJECT_ROOT"

# 构建通用参数
COMMON_ARGS="-i -I $IOS_CPUS -p $INSTALL_PREFIX -d $INSTALL_PREFIX --log-dir $LOG_DIR"

# 添加 target 参数
if [ -n "$TARGET" ]; then
    COMMON_ARGS="$COMMON_ARGS --target $TARGET"
fi

echo "============================================================"
echo "libvips iOS 编译 (Workspace 模式)"
echo "============================================================"
echo "Workspace: $SCRIPT_DIR"
echo "安装目录: $INSTALL_PREFIX"
echo "日志目录: $LOG_DIR"
if [ -n "$TARGET" ]; then
    echo "目标库: $TARGET"
else
    echo "目标库: 全部"
fi
echo "============================================================"
echo ""

# 1. 编译 libffi (特殊处理，不在 workspace 中)
echo ">>> 编译 libffi..."
"$SCRIPT_DIR/deps/libffi/build-ios.sh" "$INSTALL_PREFIX" arm64

# 2. 使用 workspace 命令编译其他库
echo ""
echo ">>> 使用 Workspace 编译..."
dart run bin/compile.dart workspace -C "example/libvips" $COMMON_ARGS

# 3. 创建 XCFramework
echo ""
echo ">>> 创建 XCFramework..."
cd "$SCRIPT_DIR"
./create-xcframework.sh

echo ""
echo "============================================================"
echo "编译完成!"
echo ""
echo "日志位置:"
echo "  $LOG_DIR"
echo ""
echo "XCFramework 位置:"
echo "  $SCRIPT_DIR/output/"
echo "============================================================"
