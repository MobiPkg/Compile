# lib.yaml 扩展配置

本文档描述 lib.yaml 的扩展配置选项。

## extra_libs - 额外产物库

某些库在编译后会产生多个静态库文件。使用 `extra_libs` 配置这些额外的库，它们会在打包 XCFramework 时被自动包含。

### 示例

```yaml
name: libwebp
type: cmake
source:
  git:
    url: https://github.com/webmproject/libwebp.git
    ref: v1.4.0

# 额外产物库（会被合并到最终 XCFramework）
extra_libs:
  - libwebpmux      # WebP mux 库（动画编码）
  - libwebpdemux    # WebP demux 库（动画解码）
  - libsharpyuv     # libwebp 的私有依赖
```

### 常见用例

| 库 | extra_libs |
|---|---|
| libwebp | libwebpmux, libwebpdemux, libsharpyuv |
| glib | libgio-2.0, libgobject-2.0, libgmodule-2.0, libgthread-2.0, libpcre2-8, libintl |

## hooks - 构建钩子

支持在构建的不同阶段执行自定义脚本，可以按平台/架构过滤。

### 可用钩子

| 钩子 | 执行时机 |
|---|---|
| `post_configure` | configure 命令执行后 |
| `post_build` | make 命令执行后（安装前） |

### 条件过滤

钩子可以按平台和架构过滤：

| 字段 | 说明 | 可选值 |
|---|---|---|
| `platform` / `platforms` | 平台过滤 | ios, android, harmony |
| `arch` / `archs` | 架构过滤 | arm64, arm64-simulator, x86_64, armv7, etc. |

### 环境变量

钩子脚本中可用的环境变量：

| 变量 | 说明 |
|---|---|
| `SOURCE_DIR` | 源码目录 |
| `BUILD_DIR` | 构建目录 |
| `INSTALL_PREFIX` | 安装目录 |
| `HOST` | 目标主机三元组 |
| `ARCH` | CPU 架构 |
| `PLATFORM` | 平台名称 |
| `SDK` | SDK 名称 (iOS) |
| `SDK_PATH` | SDK 路径 (iOS) |

### 语法示例

```yaml
hooks:
  post_configure:
    # 简单脚本（所有平台/架构都执行）
    - echo "Configure completed"
    
    # 只在 iOS 平台执行
    - platform: ios
      script: |
        echo "iOS only"
    
    # 只在 iOS arm64 真机执行
    - platform: ios
      arch: arm64
      script: |
        echo "iOS arm64 device only"
    
    # 多架构条件
    - platforms: [ios]
      archs: [arm64, arm64-simulator]
      script: |
        echo "iOS arm64 (device or simulator)"
```

### 完整示例

```yaml
name: libffi
type: autotools

# libffi 在 iOS 交叉编译时需要手动生成 fficonfig.h
hooks:
  post_configure:
    - platform: ios
      script: |
        BUILD_SUBDIR="$SOURCE_DIR/$HOST"
        if [ -d "$BUILD_SUBDIR" ]; then
          cd "$BUILD_SUBDIR"
          if [ ! -f fficonfig.h ]; then
            echo "Generating fficonfig.h..."
            cat > fficonfig.h << 'EOF'
        #define STDC_HEADERS 1
        ...
        EOF
          fi
        fi
```

## package 命令

使用 `package` 命令打包编译产物。

### XCFramework 打包

```bash
# 从 workspace 创建 XCFramework
dart run bin/compile.dart package xcframework -C path/to/workspace

# 指定目标库和输出名称
dart run bin/compile.dart package xcframework -C path/to/workspace \
  --target libvips \
  --output libvips

# 指定架构
dart run bin/compile.dart package xcframework -C path/to/workspace \
  --arch arm64 \
  --arch arm64-simulator
```

### 选项

| 选项 | 简写 | 说明 |
|---|---|---|
| `--project-path` | `-C` | Workspace 目录路径 |
| `--target` | `-t` | 目标库名称（主库） |
| `--output` | `-o` | 输出 XCFramework 名称 |
| `--install-prefix` | `-p` | 编译产物安装目录 |
| `--arch` | `-a` | 要包含的架构 |

### 工作流程

1. 解析 workspace 配置
2. 收集目标库及其所有依赖
3. 收集每个库的 `extra_libs`
4. 为每个架构合并所有静态库
5. 创建 XCFramework 结构
6. 生成 Info.plist
