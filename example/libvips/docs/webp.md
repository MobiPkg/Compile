# WebP 模块

## 概述

WebP 是 Google 开发的现代图像格式，支持有损和无损压缩，以及动画和透明度。在相同质量下，文件大小通常比 JPEG 和 PNG 小 25-35%。

## 依赖库

- **libwebp**: WebP 编解码库
- 版本: 1.4.0
- 许可证: BSD-3-Clause

## 功能

- 读取/写入 WebP 图像
- 有损压缩（类似 JPEG）
- 无损压缩（类似 PNG）
- 支持 Alpha 通道
- 支持动画 WebP

## libvips 选项

```yaml
# libvips/lib.yaml
options:
  - -Dspng=disabled
  - -Dwebp=enabled   # 启用 WebP 支持
```

## 编译

```bash
# 编译 libwebp
dart run bin/compile.dart lib -C example/libvips/deps/libwebp \
  --no-android --no-harmony --ios \
  --ios-cpu arm64 --ios-cpu arm64-simulator \
  --install-prefix example/libvips/install \
  --dependency-prefix example/libvips/install
```

## XCFramework 配置

在 `create-xcframework.sh` 的 `LIBS` 数组中添加:

```bash
"libwebp"
"libsharpyuv"  # WebP 的 YUV 转换库
```

## 使用示例

```c
#include <vips/vips.h>

// 读取 WebP
VipsImage *image;
vips_webpload("input.webp", &image, NULL);

// 保存为 WebP，质量 80
vips_webpsave(image, "output.webp", "Q", 80, NULL);

// 保存为无损 WebP
vips_webpsave(image, "output.webp", "lossless", TRUE, NULL);
```

## 注意事项

- WebP 在 iOS 14+ 原生支持显示
- 有损模式适合照片，无损模式适合图标/截图
- 动画 WebP 可替代 GIF，文件更小
