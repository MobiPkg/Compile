# libvips iOS 编译指南

本目录包含用于将 libvips 及其依赖编译为 iOS 静态库的配置文件和脚本。

## 快速开始

```bash
# 1. 安装依赖
brew install meson ninja automake autoconf libtool pkg-config

# 2. 编译真机 + 模拟器
./build-ios.sh
./build-ios-simulator.sh

# 3. 创建 XCFramework
./create-xcframework.sh
```

## XCFramework

### 输出位置

```
output/libvips.xcframework/
├── Info.plist
├── ios-arm64/                    # 真机 (24 MB)
│   ├── Headers/vips/
│   └── libvips.a
└── ios-arm64-simulator/          # Apple Silicon 模拟器 (9.5 MB)
    ├── Headers/vips/
    └── libvips.a
```

### 包含的库

XCFramework 已合并所有必需的依赖，可直接在 Xcode 项目中使用：

| 库 | 说明 |
|---|---|
| libvips | 核心图像处理库 |
| libglib-2.0 | GLib 核心库 |
| libgio-2.0 | GLib I/O 库 |
| libgobject-2.0 | GLib 对象系统 |
| libgmodule-2.0 | GLib 模块加载 |
| libgthread-2.0 | GLib 线程支持 |
| libffi | 外部函数接口 |
| libpcre2-8 | 正则表达式 |
| libintl | 国际化支持 |
| libexpat | XML 解析 |
| libz | 压缩库 |

### 在 Xcode 中使用

1. 将 `output/libvips.xcframework` 拖入 Xcode 项目
2. 在 **Build Settings** 中添加 Header Search Paths:
   - `$(SRCROOT)/path/to/libvips.xcframework/$(PLATFORM_NAME)-$(CURRENT_ARCH)/Headers`
3. 链接系统框架: `Foundation`, `CoreFoundation`

## 编译选项

### 仅编译真机 (arm64)

```bash
# 方式一：使用脚本
./build-ios.sh

# 方式二：使用 dart 编译工具
./deps/libffi/build-ios.sh $(pwd)/install  # 仅编译真机部分
dart run bin/compile.dart lib -C example/libvips/deps/zlib --ios --ios-cpu arm64 \
  --install-prefix example/libvips/install --dependency-prefix example/libvips/install
# ... 其他依赖同理
```

### 仅编译模拟器 (arm64-simulator)

```bash
# 先确保 libffi 已编译模拟器版本
./deps/libffi/build-ios.sh $(pwd)/install

# 编译其他依赖
./build-ios-simulator.sh
```

### 编译真机 + 模拟器通用包

```bash
# 1. 编译真机
./build-ios.sh

# 2. 编译模拟器
./build-ios-simulator.sh

# 3. 创建 XCFramework (自动检测并包含所有架构)
./create-xcframework.sh
```

## 依赖关系

```
libvips
├── glib (meson)
│   ├── libffi (autotools) - 需要单独编译
│   ├── pcre2 (内置 subproject)
│   └── proxy-libintl (内置 subproject)
├── expat (cmake)
├── pcre2 (cmake)
└── zlib (cmake)
```

## 详细编译步骤

### 前置要求

```bash
brew install meson ninja automake autoconf libtool pkg-config
```

### 使用 Dart 编译工具

```bash
# 从项目根目录执行
cd /path/to/mobipkg/Compile

# 设置通用参数
INSTALL_PREFIX="example/libvips/install"
COMMON_ARGS="--no-android --no-harmony --install-prefix $INSTALL_PREFIX --dependency-prefix $INSTALL_PREFIX"

# 1. 编译 libffi (特殊处理，需要使用专用脚本)
example/libvips/deps/libffi/build-ios.sh $(pwd)/$INSTALL_PREFIX

# 2. 编译 zlib (真机 + 模拟器)
dart run bin/compile.dart lib -C example/libvips/deps/zlib --ios --ios-cpu arm64 --ios-cpu arm64-simulator $COMMON_ARGS

# 3. 编译 pcre2
dart run bin/compile.dart lib -C example/libvips/deps/pcre2 --ios --ios-cpu arm64 --ios-cpu arm64-simulator $COMMON_ARGS

# 4. 编译 expat
dart run bin/compile.dart lib -C example/libvips/deps/expat --ios --ios-cpu arm64 --ios-cpu arm64-simulator $COMMON_ARGS

# 5. 编译 glib
dart run bin/compile.dart lib -C example/libvips/deps/glib --ios --ios-cpu arm64 --ios-cpu arm64-simulator $COMMON_ARGS

# 6. 编译 libvips
dart run bin/compile.dart lib -C example/libvips/libvips --ios --ios-cpu arm64 --ios-cpu arm64-simulator $COMMON_ARGS
```

**支持的 iOS CPU 类型:**

- `arm64` - 真机 (iPhone/iPad)
- `arm64-simulator` - Apple Silicon Mac 模拟器
- `x86_64` - Intel Mac 模拟器 (不推荐，libffi 有汇编兼容性问题)

## 输出目录结构

```
install/
└── ios/
    ├── arm64/                    # 真机
    │   ├── include/
    │   │   ├── vips/
    │   │   ├── glib-2.0/
    │   │   └── ...
    │   └── lib/
    │       ├── libvips.a
    │       ├── libglib-2.0.a
    │       └── ...
    └── arm64-simulator/          # 模拟器
        ├── include/
        └── lib/
```

## 当前配置

libvips 当前配置禁用了大部分可选功能以简化编译：

- **已禁用**: jpeg, png, webp, tiff, heif, gif, pdf, svg 等图像格式
- **已启用**: 基本图像处理功能

如需启用更多格式支持，需要：

1. 编译对应的依赖库（如 libjpeg-turbo, libpng 等）
2. 修改 `libvips/lib.yaml` 中的 options

## 已知限制

1. **不支持 x86_64 模拟器**: 由于 libffi 汇编代码兼容性问题
2. **arm64 模拟器**: 仅支持 Apple Silicon Mac 上的模拟器

## 添加图像格式支持

### 添加 JPEG 支持

1. 创建 `deps/libjpeg-turbo/lib.yaml`:

```yaml
name: libjpeg-turbo
type: cmake
source:
  git:
    url: https://github.com/libjpeg-turbo/libjpeg-turbo.git
    ref: 3.0.4
license: LICENSE.md

options:
  - -DENABLE_SHARED=OFF
  - -DWITH_TURBOJPEG=OFF
```

2. 编译 libjpeg-turbo
3. 修改 `libvips/lib.yaml`，将 `-Djpeg=disabled` 改为 `-Djpeg=enabled`
4. 修改 `create-xcframework.sh`，在 LIBS 数组中添加 `"libjpeg"`

### 添加 PNG 支持

1. 创建 `deps/libpng/lib.yaml`:

```yaml
name: libpng
type: cmake
source:
  git:
    url: https://github.com/glennrp/libpng.git
    ref: v1.6.44
license: LICENSE

options:
  - -DPNG_SHARED=OFF
  - -DPNG_TESTS=OFF
```

2. 编译 libpng（依赖 zlib）
3. 修改 `libvips/lib.yaml`，将 `-Dpng=disabled` 改为 `-Dpng=enabled`
4. 修改 `create-xcframework.sh`，在 LIBS 数组中添加 `"libpng16"`
