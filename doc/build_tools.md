# BuildTools

## Cmake

install cmake

```bash
sudo apt-get install cmake

# or 

brew install --cask cmake
```

## Python

install python

```bash
sudo apt-get install python3

# or

brew install python3
```

## Ninja

install ninja

```bash
sudo apt-get install ninja-build

# or

brew install ninja

# or

pip3 install ninja
```

## Meson

install meson

```bash
sudo apt-get install meson

# or

brew install meson

# or

pip3 install meson
```

## Autotools

install autotools

```bash
sudo apt-get install autoconf automake libtool

# or

brew install autoconf automake libtool
```

## rust

install rust

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

Install toolchain

```bash
rustup target add $(rustup target list | grep 'android')

rustup target add $(rustup target list | grep 'ios')

cargo install cbindgen
```

<details>

<summary>Use rust in China</summary>

### Use rust in China

See [rsproxy](https://rsproxy.cn/).

Or quickly:

```sh
vi ~/.cargo/config
```

```toml
[source.crates-io]
replace-with = 'rsproxy'

# if you want to use sparse index
# replace-with = 'rsproxy-sparse'
[source.rsproxy]
registry = "https://rsproxy.cn/crates.io-index"
[source.rsproxy-sparse]
registry = "sparse+https://rsproxy.cn/index/"
[registries.rsproxy]
index = "https://rsproxy.cn/crates.io-index"
[net]
git-fetch-with-cli = true
```

```bash
export RUSTUP_DIST_SERVER="https://rsproxy.cn"
export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"

# use sparse index
export CARGO_UNSTABLE_SPARSE_REGISTRY=true
```

```sh
# Change the default toolchain to nightly
rustup default nightly
```

</details>
