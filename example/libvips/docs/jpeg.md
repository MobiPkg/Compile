# JPEG 模块

## 概述

JPEG (Joint Photographic Experts Group) 是最广泛使用的有损图像压缩格式，适用于照片和复杂图像。

## 依赖库

- **libjpeg-turbo**: 高性能 JPEG 编解码库，使用 SIMD 指令优化
- 版本: 3.0.4
- 许可证: BSD-3-Clause, IJG

## 功能

- 读取/写入 JPEG 图像
- 支持渐进式 JPEG
- 支持 EXIF 元数据（需要 libexif）
- 高质量缩放和压缩

## libvips 选项

```yaml
# libvips/lib.yaml
options:
  - -Djpeg=enabled   # 启用 JPEG 支持
```

## 编译

```bash
# 编译 libjpeg-turbo
dart run bin/compile.dart lib -C example/libvips/deps/libjpeg-turbo \
  --no-android --no-harmony --ios \
  --ios-cpu arm64 --ios-cpu arm64-simulator \
  --install-prefix example/libvips/install \
  --dependency-prefix example/libvips/install
```

## XCFramework 配置

在 `create-xcframework.sh` 的 `LIBS` 数组中添加:

```bash
"libjpeg"
```

## 使用示例

```c
#include <vips/vips.h>

// 读取 JPEG
VipsImage *image;
vips_jpegload("input.jpg", &image, NULL);

// 保存为 JPEG，质量 85
vips_jpegsave(image, "output.jpg", "Q", 85, NULL);
```

## 注意事项

- libjpeg-turbo 使用 SIMD 优化，在 ARM64 上性能优秀
- 默认启用 SIMD，如遇问题可设置 `-DWITH_SIMD=OFF`
