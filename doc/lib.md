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

The `subpath` property is used to specify the path of the file in the archive/git/path.

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

Therefore, in order for the same parameter to have the same effect in different build systems,
compile will use the same rules for passing arguments.

`$cc $cppflags $cflags -c xxx.c`
`$cxx $cppflags $cxxflags -c xxx.cc|cpp`
`$ld $ldflags -o $`

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

### patch

Some libraries may have some issues.

A typical example:
the source url of the submodule changes, the master branch changes, but the historical tag remains unchanged.

Now, you can use the patch to fix the problem.
The patch will use `patch` command to apply the patch.

```yaml
patch:
  - path: patch/submodule-url.patch
    target: .gitmodules
    workdir: . # default is .
    before-precompile: true # default is true
    type: unified # default is unified
```

There are 2 required items and 3 optional items:

- path: The path of the patch file. It relative to the lib.yaml file.
- target: The target file of the patch. It relative to the `source`.
- workdir: The workdir of the patch. It relative to the `source`. Default is `.`.
- before-precompile: Whether to execute the patch before precompile or not. Default is `true`.
- type: The type of the patch. Default is `unified`. [See patch-type](#patch-type)

#### patch-type

The `patch-type` parameter can take one of the following values:

- `unified`
  - Command to generate patch file: `$ diff -u file1 file2 > diff.patch`
  - Command to apply patch: `$ patch -i diff.patch -u -N target_file`
- `normal`
  - Command to generate patch file: `$ diff --normal file1 file2 > diff.patch`
  - Command to apply patch: `$ patch -i diff.patch -n -N target_file`
- `context`
  - Command to generate patch file: `$ diff -c file1 file2 > diff.patch`
  - Command to apply patch: `$ patch -i diff.patch -c -N target_file`

Recommended to use `unified` type, the type is default value.

### matrix

Each group triggers a compilation.
A typical usage is that expat's cmake can only export static or shared libraries,
so it needs to be compiled multiple times with different parameters.

matrix is just support `flags` and `options`.

```yaml
matrix:
  - flags:
      c: -O2
      cxx: -O2
      cpp: -fPIC
      ld: 
    options:
      - -DEXPAT_SHARED_LIBS=OFF
  - flags:
      c: -O2
      cxx: -O2
      cpp: -fPIC
      ld: 
    options:
      - -DEXPAT_SHARED_LIBS=ON
```

The options of `matrix` will be appended after root options.  
The flags of `matrix` will be appended after each flags of root.

[GNK make doc]: https://www.gnu.org/software/make/manual/html_node/Catalogue-of-Rules.html#index-C_002c-rule-to-compile
