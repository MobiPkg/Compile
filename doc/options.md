# Options

The option here refers to the option of the `compile` subcommand,
which is not the same concept as the option in `lib.yaml`

It mainly contains 2 type:

- common options (for command line and file)
- just for command line (for command line only)

## just for command line

- `--option-file`: A yaml file used to specify compilation options.
  A yaml file used to specify compilation options.
- `-C, --project-path`: The directory where the project is located should contain the lib.yaml file.
- `just-make-shell`: A hide option, just for make shell script to help developer debug.

## common options

These options can be configured both on the command line and in option.yaml.

The option file has a higher priority. Once --option-file is configured,
**all common type options** will be ignored.

### use in command line

```shell

-a, --[no-]android              Print this usage information.
                                (defaults to on)
    --android-cpu               Set android cpu, support: arm64-v8a, armeabi-v7a, x86, x86_64.
                                [armeabi-v7a (default), arm64-v8a (default), x86 (default), x86_64 (default)]
-i, --[no-]ios                  Print this usage information.
                                (defaults to on)
-R, --[no-]remove-old-source    Remove old build files before compile.
-s, --[no-]strip                Strip symbols for dynamic libraries.
                                (defaults to on)
-g, --git-depth                 If use git to download source, set git depth to 1.
                                (defaults to "1")
-I, --install-prefix            Set install path.
-p, --dependency-prefix         Set dependencies prefix.

```

### use in option file

See whole example in [lib-example][].

## About path of option

If an option represents a file path and is a **relative path**,
the meaning of the command line and the configuration file are different.

- In the command line, the base path is the current working directory.
- In the yaml file, the base path is yaml file path.
  
[lib-example]: ../example/options/lib-option.yaml
