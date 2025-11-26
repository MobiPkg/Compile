# libvips 模块文档

本目录包含 libvips 各个可选模块的详细文档。

## 常用图像格式（推荐）

| 模块 | 文档 | 依赖库 | build.sh 变量 | 说明 |
|------|------|--------|---------------|------|
| JPEG | [jpeg.md](jpeg.md) | libjpeg-turbo | `ENABLE_JPEG` | 有损压缩，照片必备 |
| PNG | [png.md](png.md) | libpng, zlib | `ENABLE_PNG` | 无损压缩，支持透明 |
| WebP | [webp.md](webp.md) | libwebp | `ENABLE_WEBP` | 现代格式，体积小 |

## 其他图像格式

| 模块 | 文档 | 依赖库 | build.sh 变量 | 说明 |
|------|------|--------|---------------|------|
| GIF | [gif.md](gif.md) | cgif, libnsgif | `ENABLE_GIF` | 动画图像 |
| TIFF | [tiff.md](tiff.md) | libtiff | `ENABLE_TIFF` | 专业图像格式 |
| HEIF/HEIC | [heif.md](heif.md) | libheif, x265 | `ENABLE_HEIF` | Apple 默认格式 |
| AVIF | [avif.md](avif.md) | libavif, aom | `ENABLE_AVIF` | 新一代格式 |
| JPEG XL | [jpegxl.md](jpegxl.md) | libjxl | `ENABLE_JPEG_XL` | 新一代 JPEG |
| JPEG 2000 | [openjpeg.md](openjpeg.md) | openjpeg | `ENABLE_OPENJPEG` | 专业格式 |
| OpenEXR | [openexr.md](openexr.md) | OpenEXR | `ENABLE_OPENEXR` | HDR 图像 |
| FITS | [fits.md](fits.md) | cfitsio | `ENABLE_FITS` | 天文图像 |
| NIfTI | [nifti.md](nifti.md) | niftilib | `ENABLE_NIFTI` | 医学图像 |
| MATLAB | [matio.md](matio.md) | matio | `ENABLE_MATIO` | MATLAB 文件 |
| OpenSlide | [openslide.md](openslide.md) | openslide | `ENABLE_OPENSLIDE` | 数字病理 |

## 功能模块

| 模块 | 文档 | 依赖库 | build.sh 变量 | 说明 |
|------|------|--------|---------------|------|
| EXIF | [exif.md](exif.md) | libexif | `ENABLE_EXIF` | 图像元数据 |
| ICC/LCMS | [lcms.md](lcms.md) | lcms2 | `ENABLE_LCMS` | 色彩管理 |
| FFTW | [fftw.md](fftw.md) | fftw3 | `ENABLE_FFTW` | 频域处理 |
| ORC | [orc.md](orc.md) | orc | `ENABLE_ORC` | SIMD 优化 |
| Highway | [highway.md](highway.md) | highway | `ENABLE_HIGHWAY` | SIMD 优化 |
| ImageQuant | [imagequant.md](imagequant.md) | libimagequant | `ENABLE_IMAGEQUANT` | PNG 优化 |
| Quantizr | [quantizr.md](quantizr.md) | quantizr | `ENABLE_QUANTIZR` | 颜色量化 |
| Archive | [archive.md](archive.md) | libarchive | `ENABLE_ARCHIVE` | 压缩文件 |

## 文本/矢量（iOS 不推荐）

| 模块 | 文档 | 依赖库 | build.sh 变量 | 说明 |
|------|------|--------|---------------|------|
| FontConfig | - | fontconfig | `ENABLE_FONTCONFIG` | 字体配置 |
| Pango/Cairo | - | pango, cairo | `ENABLE_PANGOCAIRO` | 文本渲染 |
| SVG | [svg.md](svg.md) | librsvg | `ENABLE_RSVG` | 矢量图形 |
| PDF (Poppler) | [pdf.md](pdf.md) | poppler | `ENABLE_POPPLER` | PDF 渲染 |
| PDF (PDFium) | - | pdfium | `ENABLE_PDFIUM` | PDF 渲染 |
| ImageMagick | [magick.md](magick.md) | ImageMagick | `ENABLE_MAGICK` | 更多格式 |

## 核心依赖（始终编译）

| 库 | 说明 |
|----|------|
| glib | GLib 核心库 |
| libffi | 外部函数接口 |
| pcre2 | 正则表达式 |
| expat | XML 解析 |
| zlib | 压缩库 |
| libintl | 国际化 |

## 快速选择指南

### 最小配置

不启用任何图像格式，仅使用 libvips 的图像处理功能。

```bash
# build.sh 中所有 ENABLE_* 设为 false
```

### 推荐配置（默认）

```bash
ENABLE_JPEG=true   # 照片处理必备
ENABLE_PNG=true    # 截图、图标
ENABLE_WEBP=true   # 现代 Web 应用
```

### 完整配置

启用所有常用格式，适合需要处理多种图像格式的应用。

## 模块状态

| 状态 | 说明 |
|------|------|
| ✅ 已配置 | lib.yaml 已创建，可直接编译 |
| 📝 待配置 | 需要创建 lib.yaml |
| ❌ 不推荐 | iOS 平台依赖复杂 |

### 当前状态

**已配置 ✅**

- JPEG (libjpeg-turbo)
- PNG (libpng)
- WebP (libwebp)
- GIF (cgif)
- TIFF (libtiff)
- HEIF (libheif + libde265)
- AVIF (libavif + aom)
- JPEG 2000 (openjpeg)
- EXIF (libexif)
- LCMS (lcms2)
- FFTW (fftw)
- Highway (highway)
- ImageQuant (libimagequant)
- Archive (libarchive)

**待配置 📝**

- JPEG XL (libjxl) - 编译复杂
- OpenEXR - 依赖较多
- NIfTI - 医学图像专用
- MATLAB (matio)
- OpenSlide - 数字病理专用
- ORC - SIMD 优化

**不推荐 ❌**

- SVG (依赖 GTK/Cairo)
- PDF (依赖复杂)
- ImageMagick (体积大)
- FontConfig/Pango (文本渲染)
