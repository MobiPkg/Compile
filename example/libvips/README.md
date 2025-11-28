# libvips iOS 编译指南

本目录包含用于将 libvips 及其依赖编译为 iOS 静态库的配置文件和脚本。

## 快速开始

### 方式一：使用 Shell 脚本

```bash
# 1. 安装依赖
brew install meson ninja automake autoconf libtool pkg-config

# 2. 编译真机 + 模拟器
./build-ios.sh
./build-ios-simulator.sh

# 3. 创建 XCFramework
./create-xcframework.sh
```

### 方式二：使用 Workspace 命令（推荐）

```bash
# 1. 安装依赖
brew install meson ninja automake autoconf libtool pkg-config

# 2. 使用 workspace 命令编译所有库
cd /path/to/mobipkg/Compile
dart run bin/compile.dart workspace -C example/libvips \
  --ios --ios-cpu arm64 --ios-cpu arm64-simulator

# 3. 使用 package 命令创建 XCFramework
dart run bin/compile.dart package xcframework -C example/libvips \
  --target libvips --output libvips
```

### 方式三：使用配置化构建脚本

```bash
# 使用 build.sh 可以灵活配置启用的模块
./build.sh

# 或指定架构
./build.sh arm64           # 仅真机
./build.sh arm64-simulator # 仅模拟器
./build.sh all             # 全部（默认）
```

## XCFramework

### 输出位置

```text
output/libvips.xcframework/
├── Info.plist
├── ios-arm64/                    # 真机 (23 MB)
│   ├── Headers/
│   │   ├── vips/                 # libvips 头文件
│   │   ├── glib-2.0/             # GLib 头文件
│   │   ├── gio-unix-2.0/         # GIO 头文件
│   │   ├── ffi.h                 # libffi 头文件
│   │   ├── zlib.h                # zlib 头文件
│   │   └── ...
│   └── libvips.a                 # 合并的静态库
└── ios-arm64-simulator/          # Apple Silicon 模拟器 (24 MB)
    ├── Headers/
    └── libvips.a
```

### 包含的库

XCFramework 已合并所有必需的依赖为单个 `libvips.a`：

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
2. 在 **Build Settings > Header Search Paths** 中添加（递归）:

```text
$(SRCROOT)/path/to/libvips.xcframework/ios-$(PLATFORM_NAME)/Headers
$(SRCROOT)/path/to/libvips.xcframework/ios-$(PLATFORM_NAME)/Headers/glib-2.0
```

3. 在代码中引用:

```c
#include <vips/vips.h>
#include <glib.h>
```

4. 在 **Build Phases > Link Binary With Libraries** 中添加:
   - `libiconv.tbd`（字符编码转换）
   - `libresolv.tbd`（DNS 解析）
   - `Foundation.framework`
   - `CoreFoundation.framework`

## 集成到 CocoaPods

创建 `libvips.podspec`:

```ruby
Pod::Spec.new do |s|
  s.name         = 'libvips'
  s.version      = '8.16.0'
  s.summary      = 'libvips image processing library for iOS'
  s.homepage     = 'https://github.com/libvips/libvips'
  s.license      = { :type => 'LGPL-2.1' }
  s.author       = { 'libvips' => 'vipsip@jiscmail.ac.uk' }
  s.platform     = :ios, '12.0'
  s.source       = { :http => 'URL_TO_YOUR_XCFRAMEWORK.zip' }
  
  s.vendored_frameworks = 'libvips.xcframework'
  s.libraries = 'iconv', 'resolv'
  s.frameworks = 'Foundation', 'CoreFoundation'
  
  s.pod_target_xcconfig = {
    'HEADER_SEARCH_PATHS' => '$(PODS_ROOT)/libvips/libvips.xcframework/ios-$(PLATFORM_NAME)/Headers $(PODS_ROOT)/libvips/libvips.xcframework/ios-$(PLATFORM_NAME)/Headers/glib-2.0'
  }
end
```

使用:

```ruby
# Podfile
pod 'libvips', :path => './path/to/libvips.podspec'
```

## 集成到 Swift Package Manager

创建 `Package.swift`:

```swift
// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "libvips",
    platforms: [.iOS(.v12)],
    products: [
        .library(name: "libvips", targets: ["libvips"])
    ],
    targets: [
        .binaryTarget(
            name: "libvips",
            path: "libvips.xcframework"
        )
    ]
)
```

在项目中添加:

```swift
// Package.swift 依赖
.package(path: "./path/to/libvips-package")
```

**注意**: Swift Package 需要手动在 Xcode 中添加 `libiconv.tbd` 和 `libresolv.tbd`。

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

## lib.yaml 扩展配置

### extra_libs - 额外产物库

某些库编译后会产生多个静态库文件，使用 `extra_libs` 配置：

```yaml
# deps/libwebp/lib.yaml
name: libwebp
type: cmake
# ...

extra_libs:
  - libwebpmux      # WebP mux 库（动画编码）
  - libwebpdemux    # WebP demux 库（动画解码）
  - libsharpyuv     # libwebp 的私有依赖
```

这些额外库会在使用 `package xcframework` 命令时自动包含。

### hooks - 构建钩子

支持在构建的不同阶段执行自定义脚本，可以按平台/架构过滤：

```yaml
# deps/libffi/lib.yaml
name: libffi
type: autotools
# ...

hooks:
  post_configure:
    # 只在 iOS 平台执行
    - platform: ios
      script: |
        echo "iOS specific post-configure hook"
    
    # 只在 iOS arm64 真机执行
    - platform: ios
      arch: arm64
      script: |
        echo "iOS arm64 device only"
```

详细文档参见 `doc/lib-yaml-extensions.md`。

## 使用 Compile 命令构建 libffi

libffi 现在可以直接使用 compile 命令构建，不再需要单独的 shell 脚本：

```bash
cd /path/to/mobipkg/Compile

# 编译 libffi（真机 + 模拟器）
dart run bin/compile.dart lib -C example/libvips/deps/libffi \
  --ios --ios-cpu arm64 --ios-cpu arm64-simulator \
  --install-prefix example/libvips/install \
  --dependency-prefix example/libvips/install
```

libffi 的 `lib.yaml` 配置了 `hooks.post_configure` 钩子，会在 iOS 交叉编译时自动生成必要的 `fficonfig.h` 文件。

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

## 使用 Dart Compile 工具构建 XCFramework

完整的编译和打包流程：

```bash
# 进入项目根目录
cd /path/to/mobipkg/Compile

# 设置参数
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
```

### 仅编译特定架构

```bash
# 仅编译真机
dart run bin/compile.dart lib -C example/libvips/libvips \
  --no-android --no-harmony --ios --ios-cpu arm64 \
  --install-prefix example/libvips/install \
  --dependency-prefix example/libvips/install

# 仅编译模拟器
dart run bin/compile.dart lib -C example/libvips/libvips \
  --no-android --no-harmony --ios --ios-cpu arm64-simulator \
  --install-prefix example/libvips/install \
  --dependency-prefix example/libvips/install
```

### 支持的 iOS CPU 类型

| 类型 | 说明 |
|------|------|
| `arm64` | iPhone/iPad 真机 |
| `arm64-simulator` | Apple Silicon Mac 模拟器 |
| `x86_64` | Intel Mac 模拟器（不推荐） |

## 自定义 libvips XCFramework

### 添加新的依赖库

1. 在 `deps/` 目录下创建库配置:

```bash
mkdir -p deps/mylib
```

2. 创建 `deps/mylib/lib.yaml`:

```yaml
name: mylib
type: cmake  # 或 meson, autotools
source:
  git:
    url: https://github.com/example/mylib.git
    ref: v1.0.0
license: LICENSE

options:
  - -DBUILD_SHARED_LIBS=OFF
  - -DBUILD_TESTING=OFF
```

3. 编译新库:

```bash
dart run bin/compile.dart lib -C example/libvips/deps/mylib \
  --no-android --no-harmony --ios \
  --ios-cpu arm64 --ios-cpu arm64-simulator \
  --install-prefix example/libvips/install \
  --dependency-prefix example/libvips/install
```

4. 修改 `libvips/lib.yaml` 启用对应功能

5. 修改 `create-xcframework.sh`，在 `LIBS` 数组中添加新库名

### 修改 libvips 编译选项

编辑 `libvips/lib.yaml` 中的 `options` 部分:

```yaml
options:
  # 启用/禁用图像格式
  - -Djpeg=enabled      # 需要 libjpeg-turbo
  - -Dpng=enabled       # 需要 libpng
  - -Dwebp=enabled      # 需要 libwebp
  - -Dheif=enabled      # 需要 libheif
  - -Dtiff=disabled
  
  # 其他功能
  - -Dcgif=disabled     # GIF 支持
  - -Dexif=disabled     # EXIF 元数据
  - -Dlcms=disabled     # 色彩管理
```

### 自定义 XCFramework 包含的库

编辑 `create-xcframework.sh` 中的 `LIBS` 数组:

```bash
LIBS=(
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
    # 添加自定义库
    "libjpeg"
    "libpng16"
    "libwebp"
)
```

### 完整自定义示例：添加 JPEG + PNG 支持

```bash
# 1. 编译 libjpeg-turbo
dart run bin/compile.dart lib -C example/libvips/deps/libjpeg-turbo \
  --no-android --no-harmony --ios \
  --ios-cpu arm64 --ios-cpu arm64-simulator \
  --install-prefix example/libvips/install \
  --dependency-prefix example/libvips/install

# 2. 编译 libpng
dart run bin/compile.dart lib -C example/libvips/deps/libpng \
  --no-android --no-harmony --ios \
  --ios-cpu arm64 --ios-cpu arm64-simulator \
  --install-prefix example/libvips/install \
  --dependency-prefix example/libvips/install

# 3. 修改 libvips/lib.yaml 启用 jpeg 和 png
# 4. 重新编译 libvips
dart run bin/compile.dart lib -C example/libvips/libvips \
  --no-android --no-harmony --ios \
  --ios-cpu arm64 --ios-cpu arm64-simulator \
  --install-prefix example/libvips/install \
  --dependency-prefix example/libvips/install

# 5. 修改 create-xcframework.sh 添加新库
# 6. 重新创建 XCFramework
cd example/libvips && ./create-xcframework.sh
```
