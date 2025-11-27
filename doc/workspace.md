# Workspace Configuration / Workspace 配置

Workspace is a collection of library definitions with dependency management
and automatic compilation ordering.

Workspace 是一个包含多个库定义的工作空间，支持依赖管理和自动编译顺序。

## Configuration Files / 配置文件

### workspace.yaml

Create `workspace.yaml` in the workspace root directory.

在工作空间根目录创建 `workspace.yaml` 文件：

```yaml
name: my-workspace

libs:
  # Base libraries / 基础库
  - name: zlib
    path: deps/zlib
  - name: libffi
    path: deps/libffi
  
  # Libraries depending on zlib / 依赖 zlib 的库
  - name: libpng
    path: deps/libpng
  
  # Main library / 主库
  - name: mylib
    path: mylib
```

### Field Description / 字段说明

| Field / 字段 | Required / 必填 | Description / 说明 |
|------|------|------|
| `name` | No / 否 | Workspace name, defaults to directory name / 名称，默认使用目录名 |
| `libs` | Yes / 是 | Library list / 库列表 |
| `libs[].name` | Yes / 是 | Unique identifier for dependency reference / 唯一标识符，用于依赖引用 |
| `libs[].path` | Yes / 是 | Relative path to workspace / 相对于 workspace 的路径 |

## Dependencies in lib.yaml / lib.yaml 中的依赖

Use `deps` field in `lib.yaml` to declare dependencies.

在 `lib.yaml` 中使用 `deps` 字段声明依赖：

```yaml
name: mylib
type: meson

deps:
  - zlib
  - libpng
  - glib

# ... other config / 其他配置
```

Dependency names must match the `name` defined in `workspace.yaml`.

依赖名称必须与 `workspace.yaml` 中定义的 `name` 一致。

## Command Line Usage / 命令行使用

### Compile Entire Workspace / 编译整个 Workspace

```bash
# Compile all libraries (auto-ordered by dependencies)
# 编译所有库（自动按依赖顺序）
dart run bin/compile.dart workspace -C path/to/workspace -i

# Short form / 简写
compile ws -C path/to/workspace -i
```

### Compile Specific Library / 编译指定库

```bash
# Compile mylib and its dependencies only
# 只编译 mylib 及其依赖
dart run bin/compile.dart workspace -C path/to/workspace -i --target mylib
```

### Common Options / 常用选项

| Option / 选项 | Short / 简写 | Description / 说明 |
|------|------|------|
| `--target` | `-t` | Target library, compile it with dependencies / 目标库及其依赖 |
| `--ios` | `-i` | Compile for iOS / 编译 iOS 版本 |
| `--android` | `-a` | Compile for Android / 编译 Android 版本 |
| `--ios-cpu` | `-I` | iOS CPU architecture / iOS CPU 架构 |
| `--install-prefix` | `-p` | Installation directory / 安装目录 |
| `--dependency-prefix` | `-d` | Dependencies directory / 依赖库目录 |
| `--log-dir` | `-L` | Log directory / 日志目录 |

## Dependency Resolution / 依赖解析

Workspace automatically resolves dependencies and compiles in topological order.

Workspace 会自动解析依赖关系并按拓扑顺序编译：

1. Parse `deps` field from all libraries / 解析所有库的 `deps` 字段
2. Build dependency graph / 构建依赖图
3. Topological sort using Kahn's algorithm / 使用 Kahn 算法进行拓扑排序
4. Compile in order (dependencies first) / 按顺序编译（先编译依赖）

### Circular Dependency Detection / 循环依赖检测

Compilation will fail if circular dependencies are detected.

如果存在循环依赖，编译会失败并提示相关库名称。

## Example / 示例

See `example/libvips/` directory:

参考 `example/libvips/` 目录：

```text
example/libvips/
├── workspace.yaml          # Workspace config / 配置
├── build_with_workspace.sh # Build script / 编译脚本
├── deps/
│   ├── zlib/
│   │   └── lib.yaml
│   ├── glib/
│   │   └── lib.yaml       # deps: [libffi, pcre2, zlib]
│   └── libpng/
│       └── lib.yaml       # deps: [zlib]
└── libvips/
    └── lib.yaml           # deps: [glib, zlib, libpng, ...]
```
