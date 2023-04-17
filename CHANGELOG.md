# CHANGLOG

## UnRelease

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
