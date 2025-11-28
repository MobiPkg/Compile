# Compile - C/C++ 跨平台编译工具

本项目是 mobipkg 的一部分。

目标是通过配置文件编译可用的 iOS/Android/HarmonyOS 库。

[English](README.md) | 中文

## 环境要求

- 平台
  - macOS（编译 iOS 必需）
  - Linux（未测试）
- Android NDK 25（编译 Android 必需）
- Xcode 14.x（编译 iOS 必需）
- Git（源码为 git 时必需）
- autoconf（源码为 autotools 时必需）
- wget（源码为 http/https 时必需）
  - tar（源码为 tar 时必需）
  - unzip（源码为 zip 时必需）
- cp（源码为本地路径时必需）

## 环境变量

### ANDROID_NDK_HOME

Android NDK 路径。如果未设置，工具会尝试从以下环境变量推断：
- `ANDROID_SDK_ROOT`
- `ANDROID_HOME`
- `ANDROID_SDK`

并自动查找 SDK 下 `ndk/` 目录中的最新版本。

### MOBIPKG_PREFIX

如果配置了此环境变量，所有库将安装到此目录。（默认：`<lib>/install`）

同时，编译时需要的依赖也会从此目录查找。

命令行选项或配置文件可以覆盖此值。

## 命令使用

```bash
compile -h
```

简单编译步骤：

```bash
compile create -C example

cd example
# 编辑 lib.yaml

# 编译
compile lib -C .
```

## 平台与架构选项

### 平台开关

| 选项 | 默认值 | 说明 |
|------|--------|------|
| `-a, --[no-]android` | `true` | 编译 Android 库 |
| `-i, --[no-]ios` | macOS 上为 `true`，其他平台为 `false` | 编译 iOS 库 |
| `-H, --[no-]harmony` | `false` | 编译鸿蒙库 |

### CPU 架构选项

#### Android (`--android-cpu`)

支持：`arm64-v8a`, `armeabi-v7a`, `x86`, `x86_64`

默认：所有架构

#### iOS (`--ios-cpu`)

支持：`arm64`, `arm64-simulator`, `x86_64`, `all`

默认：`arm64`, `arm64-simulator`（支持 M 系列芯片模拟器）

使用 `--ios-cpu all` 包含 `x86_64`（Intel Mac 模拟器）。

#### 鸿蒙 (`--harmony-cpu`)

支持：`arm64-v8a`, `armeabi-v7a`, `x86_64`

默认：所有架构

### 使用示例

```bash
# macOS：默认编译 Android + iOS
compile lib -C .

# 仅编译 iOS（跳过 Android）
compile lib -C . --no-android

# 仅编译 Android（跳过 iOS）
compile lib -C . --no-ios

# 编译指定 iOS 架构
compile lib -C . --no-android --ios-cpu arm64

# 编译所有 iOS 架构（包括 x86_64）
compile lib -C . --no-android --ios-cpu all

# 编译鸿蒙
compile lib -C . --harmony
```

## 支持的构建工具

- [x] autotools
- [x] cmake
- [x] meson

## 支持的源码类型

- [x] git
- [x] file（本地文件）
- [x] http

## 示例

[example](https://github.com/mobipkg/compile/tree/main/example) 目录包含一些示例库。

### 定义库配置

创建 `lib.yaml` 文件：

```yaml
name: libffi
type: autotools
source:
  git: 
    url: https://github.com/libffi/libffi.git
    ref: v3.4.4
license: LICENSE
```

### 定义 .gitignore

建议添加 .gitignore 文件：

```gitignore
build/
source/
install/
```

### Workspace（依赖管理）

Workspace 允许你定义多个库及其依赖关系，编译时会自动按拓扑顺序编译。

**workspace.yaml**

```yaml
name: my-workspace
libs:
  - name: zlib
    path: deps/zlib
  - name: libpng
    path: deps/libpng
  - name: mylib
    path: mylib
```

**lib.yaml（添加 deps 字段）**

```yaml
name: mylib
type: meson
deps:
  - zlib
  - libpng
```

**编译命令**

```bash
# 编译整个 workspace
compile workspace -C path/to/workspace -i

# 只编译指定库及其依赖
compile workspace -C path/to/workspace -i --target mylib
```

### lib.yaml 扩展配置

#### extra_libs - 额外产物库

某些库编译后会产生多个静态库文件：

```yaml
name: libwebp
type: cmake

extra_libs:
  - libwebpmux
  - libwebpdemux
  - libsharpyuv
```

#### hooks - 构建钩子

在构建的不同阶段执行自定义脚本，支持按平台/架构过滤：

```yaml
name: libffi
type: autotools

hooks:
  post_configure:
    # 简单脚本（所有平台执行）
    - echo "Configure completed"
    
    # 仅 iOS
    - platform: ios
      script: |
        echo "iOS specific hook"
    
    # 仅 iOS arm64 真机
    - platform: ios
      arch: arm64
      script: |
        echo "iOS arm64 device only"
```

### Package 命令

从编译产物创建 XCFramework：

```bash
compile package xcframework -C path/to/workspace --target mylib --output mylib
```

## 其他文档

- [lib 配置](doc/lib.md)
- [选项配置](doc/options.md)
- [项目 yaml 配置](doc/project-yaml.md)
- [workspace 配置](doc/workspace.md)
- [lib.yaml 扩展](doc/lib-yaml-extensions.md)
- [示例列表](doc/example-list.md)
- [开发文档](doc/Develop.md)

## 许可证

[Apache-2.0 License](LICENSE)
