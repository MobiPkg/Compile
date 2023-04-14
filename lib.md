# About lib.yaml

The lib.yaml file is the configuration file for the library.

## Options

### name

The name of the library.

```yaml
name: libffi
```

### type

The type of the library.

type can be one of the following:

- autotools
- cmake
- meson

```yaml
type: autotools
```

### source

The source of the library.

source can be one of the following:

- git
  - url: The url of the git repository.
  - ref: The ref of the git repository.
- http
  - url: The url of the http file.
  - type: The type of the http file. [See http-type](#http-type)
- path: The path of the local file.

Another property is subpath, which is the path of the file in the archive/git/path.

```yaml
source:
  git:
    url: https://github.com/libffi/libffi.git
    ref: v3.3
  subpath: . # default is .

# or
source:
  http: 
    url: https://github.com/madler/zlib/archive/refs/tags/v1.2.13.tar.gz
    type: tar.gz
  subpath: zlib-1.2.13

# or
source:
  path: /path/to/libffi
```

#### http-type

http-type can be one of the following:

- tar
- tar.gz
- tgz
- tar.bz2
- tbz2
- 7z
- zip

### license

The license path of the archive or git repository.

Usually, the license file is `LICENSE`, `COPYING` or `LICENSE.md`.

```yaml
license: LICENSE
```

The license will copy to install directory: `{prefix}/license/{name}-license`.

### flags

The flags have the following properties:

- c: The flags for C compiler.
- cxx: The flags for C++ compiler.
- cpp: The flags for C preprocessor.
- ld: The flags for linker.

**Note** of cpp:
In actual use, it is a general option and will be appended before c flags and cxx flags.
See [GNK make doc][] to learn more.

```yaml
flags:
  c: -O2
  cxx: -O2
  cpp: -fPIC
  ld: -L/path/to/lib
```

### precompile

Shell commands to be executed before compiling.

A typical example: an autotools project might contain `autogen.sh`,
before compiling, you need to execute `./autogen.sh` to generate `configure`.

```yaml
precompile:
  - ./autogen.sh
```

### options

Some options when performing compilation

Such as `--prefix` for autotools, `-DCMAKE_INSTALL_PREFIX` for cmake, etc.

These commands will be appended to the compile command as-is.

```yaml

# For autotools will append to `./configure`
options:
  - --enable-shared
  - --disable-static

# For cmake will append to `cmake -S . -B build`
options:
  - -DLIBFFI_BUILD_SHARED:BOOL=ON

# For meson will append to `meson setup`
options:
  - --debug
```

[GNK make doc]: https://www.gnu.org/software/make/manual/html_node/Catalogue-of-Rules.html#index-C_002c-rule-to-compile
