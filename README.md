# Compile c/c++ code to dynamic/static library

This package is part of mobipkg.

The goal is to compile an available iOS/android library by configuration file.

## Requirements

Because this is the environment used by developers, please test other environments by yourself

- Platform
  - macOS (If you want to compile iOS)
  - linux (No tested)
- Android NDK 25 (If you want to compile android)
- XCode 14.x (If you want to compile iOS)
- Git (If your source url is git)
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
# 1. Create by template
compile create -C example
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

### Other documents

- [Config lib](doc/lib.md)
- [Config option](doc/options.md)
- [Config project yaml](doc/project-yaml.md)
- [Example list](doc/example-list.md)
- [Develop](doc/Develop.md)
- [Why](doc/WAY%26HOW.md)

## LICENSE

[Apache-2.0 License](LICENSE)
