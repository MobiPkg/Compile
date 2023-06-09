# CHANGLOG

## UnRelease

- Add `rust` compiler.
- Refactored `flags`.
- Fix meson build error with flag.
- Support iOS cpu types.

## 0.0.6

- Rename `compile` command to `lib`.
- Fix meson compile error.
- Support patch for `lib.yaml`.
- Add `CMAKE_SYSTEM_PROCESSOR` to `cmake` compile.
- Update `template` command.
- Add `reporter` log for debug.
- Add `OBJC` and `OBJCXX` env for iOS.
- Fix http type check problem.
- Use `brew info` when create lib.
- Support HttpSource type: `tar.xz`.
- Report error for just `Makefile` project.
- Lipo for iOS lib will ignore `bin`.
- Fix lipo iOS lib for just header lib.

## 0.0.5

- Add abbr for `--option-file`.
- Fix cmake compile problem for x86_64.

## 0.0.4

- Change `meson` compile lib type to `both`.
- Add `--dependency-prefix` for compile command.
- Support `matrix` for `lib.yaml`.
- Support `android-cpu` type for compile command.
- Support `option-file` for compile command. (See [example-option-file](example/options/lib-option.yaml))
- Support `project` command.
- Temporarily removed multiple ios cpu with cmake compile.
- Fix install prefix problem.
- Fix iOS cmake compile problem.

## 0.0.3

- Support for `strip` option.
- Support iOS mutil arch in one package.
- Support `MOBIPKG_PREFIX` env.
- Support custom args for `lib.yaml`.
- Support find lib from `MOBIPKG_PREFIX`.
- Auto detect `type` for `lib.yaml`.
- Remove compile commands.
- Support custom `install-prefix`.

## 0.0.2

- Support for CMake.
- Support source type `http`

## 0.0.1

- Initial version.
- Support for autotools.
- Support source type `git`.
