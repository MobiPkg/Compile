# About project command

The compile have a `project` command, it can be used to create a project template.

What it does is compile all libs in order.

Because the c library will contain various dependencies, and using this method to compile all the required class libraries can be compiled in order.

## Command usage

The project command is same as compile command, all options are same.
See [options](options.md) for more details.

The only difference is that `compile` looks for `lib.yaml` and this `project` command looks for `project.yaml`.

The automatically supported filenames are `project.yaml` and `project.yml`.

## yaml config

```yaml
libs:
  - path: ../example/git-cmake/zlib
  - path: ../example/git-autotools/libpng 
```

The path here is relative to the directory where `project.yaml` is located.
