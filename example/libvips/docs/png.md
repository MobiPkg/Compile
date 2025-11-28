# PNG 模块

## 概述

PNG (Portable Network Graphics) 是一种无损压缩的位图图像格式，支持透明度，适用于图标、截图和需要精确颜色的图像。

## 依赖库

- **libpng**: PNG 参考实现库
- **zlib**: 压缩库（PNG 使用 DEFLATE 压缩）
- 版本: 1.6.44
- 许可证: libpng License

## 功能

- 读取/写入 PNG 图像
- 支持 Alpha 通道（透明度）
- 支持 8/16 位色深
- 支持隔行扫描（Adam7）
- 支持 ICC 色彩配置文件

## libvips 选项

```yaml
# libvips/lib.yaml
options:
  - -Dpng=enabled   # 启用 PNG 支持
```

## 编译

```bash
# 先编译 zlib（如果尚未编译）
dart run bin/compile.dart lib -C example/libvips/deps/zlib \
  --no-android --no-harmony --ios \
  --ios-cpu arm64 --ios-cpu arm64-simulator \
  --install-prefix example/libvips/install \
  --dependency-prefix example/libvips/install

# 编译 libpng
dart run bin/compile.dart lib -C example/libvips/deps/libpng \
  --no-android --no-harmony --ios \
  --ios-cpu arm64 --ios-cpu arm64-simulator \
  --install-prefix example/libvips/install \
  --dependency-prefix example/libvips/install
```

## XCFramework 配置

在 `create-xcframework.sh` 的 `LIBS` 数组中添加:

```bash
"libpng16"
```

## 使用示例

```c
#include <vips/vips.h>

// 读取 PNG
VipsImage *image;
vips_pngload("input.png", &image, NULL);

// 保存为 PNG，压缩级别 6
vips_pngsave(image, "output.png", "compression", 6, NULL);
```

## 注意事项

- libpng 依赖 zlib，确保先编译 zlib
- PNG 是无损格式，文件通常比 JPEG 大
- 适合需要透明度或精确颜色的场景
