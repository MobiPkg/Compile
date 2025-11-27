# Compile - Cross-platform C/C++ Build Tool

This package is part of mobipkg.

The goal is to compile iOS/Android/HarmonyOS libraries via configuration files.

English | [中文](README_zh.md)

## Requirements

Because this is the environment used by developers, please test other environments by yourself

- Platform
  - macOS (If you want to compile iOS)
  - linux (No tested)
- Android NDK 25 (If you want to compile android)
- XCode 14.x (If you want to compile iOS)
- Git (If your source url is git)
- autoconf (If your source is autotools)
- wget (If your source url is http/https)
  - tar (If your source is tar)
    - gzip (If your source is gzip/tar.gz/tgz)
    - bzip2 (If your source is bzip2/tar.bz2/tbz2)
    - xz (If your source is xz/tar.xz)
    - lamz (If your source is lamz/tar.lamz)
  - unzip (If your source is zip)
  - 7zip (If your source is 7zip)
- cp (If your source is path), the cp command is IEEE Std 1003.2 (“POSIX.2”) compliant.

If you want to compile c

## Environment Variables

### ANDROID_NDK_HOME

Android NDK 25 Path, other version is not tested.

### MOBIPKG_PREFIX

If this env is configured, all libraries will be installed into this directory. (Default: `<lib>/install`)

At the same time, if compile need some dependencies, it will find them in this directory.

Command line option or option-file can override this value.

## Usage for command

```bash
compile -h
```

Simple compile steps:

```bash
compile create -C example

cd example
# edit lib.yaml

# compile
compile lib -C .
```

## Platform & Architecture Options

### Platform Flags

| Flag | Default | Description |
|------|---------|-------------|
| `-a, --[no-]android` | `true` | Compile Android library |
| `-i, --[no-]ios` | `true` on macOS, `false` otherwise | Compile iOS library |
| `-H, --[no-]harmony` | `false` | Compile HarmonyOS library |

### CPU Architecture Options

#### Android (`--android-cpu`)

Supported: `arm64-v8a`, `armeabi-v7a`, `x86`, `x86_64`

Default: all architectures

#### iOS (`--ios-cpu`)

Supported: `arm64`, `arm64-simulator`, `x86_64`, `all`

Default: `arm64`, `arm64-simulator` (M-series Mac simulator support)

Use `--ios-cpu all` to include `x86_64` (Intel Mac simulator).

#### HarmonyOS (`--harmony-cpu`)

Supported: `arm64-v8a`, `armeabi-v7a`, `x86_64`

Default: all architectures

### Examples

```bash
# macOS: compile Android + iOS (default)
compile lib -C .

# Compile iOS only (skip Android)
compile lib -C . --no-android

# Compile Android only (skip iOS)
compile lib -C . --no-ios

# Compile specific iOS architectures
compile lib -C . --no-android --ios-cpu arm64

# Compile all iOS architectures including x86_64
compile lib -C . --no-android --ios-cpu all

# Compile with HarmonyOS
compile lib -C . --harmony
```

## Supported

- Tools:
  - [x] autotools
  - [x] cmake
  - [x] meson

- Source type
  - [x] git
  - [x] file
  - [x] http

## Example usage

The [example](https://github.com/mobipkg/compile/tree/main/example) directory contains some example libraries.

### Define your library

Like the example, in general, you need to define a file: `lib.yaml`, which is conventional and its name cannot be changed.

```yaml
name: libffi
type: autotools # or other types, you can run `compile support type` to see all types
source:
  git: 
    url: https://github.com/libffi/libffi.git
    ref: v3.4.4
license: LICENSE
```

### Defind your .gitignore

In general, it is also recommended that you include a .gitignore file
It is defined as follows:

```gitignore
build/
source/
install/
```

### Workspace (Dependency Management)

Workspace allows you to define multiple libraries with dependencies.
The compiler will automatically resolve and compile them in topological order.

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

**lib.yaml (add deps field)**

```yaml
name: mylib
type: meson
deps:
  - zlib
  - libpng
# ... other config
```

**Commands**

```bash
# Compile entire workspace
compile workspace -C path/to/workspace -i

# Compile specific lib with its dependencies
compile workspace -C path/to/workspace -i --target mylib
```

### lib.yaml Extensions

#### extra_libs

Some libraries produce multiple static library files. Use `extra_libs` to include them:

```yaml
name: libwebp
type: cmake
# ...

extra_libs:
  - libwebpmux
  - libwebpdemux
  - libsharpyuv
```

#### hooks

Execute custom scripts at different build stages, with platform/arch filtering:

```yaml
name: libffi
type: autotools
# ...

hooks:
  post_configure:
    # Simple script (runs on all platforms)
    - echo "Configure completed"
    
    # iOS only
    - platform: ios
      script: |
        echo "iOS specific hook"
    
    # iOS arm64 device only
    - platform: ios
      arch: arm64
      script: |
        echo "iOS arm64 device only"
```

### Package Command

Create XCFramework from compiled libraries:

```bash
# Create XCFramework from workspace
compile package xcframework -C path/to/workspace --target mylib --output mylib
```

### Other documents

- [Config lib](doc/lib.md)
- [Config option](doc/options.md)
- [Config project yaml](doc/project-yaml.md)
- [Config workspace](doc/workspace.md)
- [lib.yaml Extensions](doc/lib-yaml-extensions.md)
- [Example list](doc/example-list.md)
- [Develop](doc/Develop.md)
- [Why](doc/WAY%26HOW.md)

## LICENSE

[Apache-2.0 License](LICENSE)
