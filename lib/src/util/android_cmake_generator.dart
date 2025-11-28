import 'dart:io';
import 'package:path/path.dart';

/// Android CMake 配置生成器
/// 在 workspace 编译完成后，生成 CMake 配置文件和 install.md
class AndroidCmakeGenerator {
  final String installDir;
  final String libName;
  final List<String> staticLibs;
  final List<String> includeDirs;

  AndroidCmakeGenerator({
    required this.installDir,
    required this.libName,
    required this.staticLibs,
    required this.includeDirs,
  });

  /// 从 install 目录扫描并生成配置
  factory AndroidCmakeGenerator.fromInstallDir(String installDir, String libName) {
    final staticLibs = <String>[];
    final includeDirs = <String>[];

    // 扫描所有 Android ABI 目录
    final androidDir = Directory(join(installDir, 'android'));
    if (androidDir.existsSync()) {
      // 获取 ABI 目录来扫描库文件，优先选择 arm64-v8a
      final abiDirs = androidDir.listSync()
          .whereType<Directory>()
          .where((d) => !basename(d.path).startsWith('.'))
          .toList();
      // 优先选择 arm64-v8a，因为它通常有最完整的库
      abiDirs.sort((a, b) {
        final aName = basename(a.path);
        final bName = basename(b.path);
        if (aName == 'arm64-v8a') return -1;
        if (bName == 'arm64-v8a') return 1;
        return aName.compareTo(bName);
      });
      
      if (abiDirs.isNotEmpty) {
        final firstAbi = abiDirs.first;
        final libDir = Directory(join(firstAbi.path, 'lib'));
        if (libDir.existsSync()) {
          // Scan all .a files
          for (final entity in libDir.listSync()) {
            if (entity is File && entity.path.endsWith('.a')) {
              // 排除符号链接指向的文件（如 libpng.a -> libpng16.a）
              final fileName = basename(entity.path);
              if (!staticLibs.contains(fileName)) {
                staticLibs.add(fileName);
              }
            }
          }
          // 按依赖顺序排序（主库在前，依赖库在后）
          staticLibs.sort(_compareLibOrder);
        }

        // 扫描 include 目录
        final includeDir = Directory(join(firstAbi.path, 'include'));
        if (includeDir.existsSync()) {
          includeDirs.add('include');
          // 扫描所有子目录
          for (final entity in includeDir.listSync()) {
            if (entity is Directory) {
              includeDirs.add('include/${basename(entity.path)}');
            }
          }
        }

        // 检查 glib 特殊的 include 路径
        final glibConfigDir = Directory(join(firstAbi.path, 'lib', 'glib-2.0', 'include'));
        if (glibConfigDir.existsSync()) {
          includeDirs.add('lib/glib-2.0/include');
        }
      }
    }

    return AndroidCmakeGenerator(
      installDir: installDir,
      libName: libName,
      staticLibs: staticLibs,
      includeDirs: includeDirs,
    );
  }

  /// 库排序比较函数，主库在前，依赖库在后
  static int _compareLibOrder(String a, String b) {
    // 定义优先级（数字越小越靠前）
    int getPriority(String lib) {
      if (lib.contains('vips')) return 0;
      if (lib.contains('gio')) return 10;
      if (lib.contains('gobject')) return 11;
      if (lib.contains('gmodule')) return 12;
      if (lib.contains('glib')) return 13;
      if (lib.contains('gthread')) return 14;
      if (lib.contains('intl')) return 15;
      if (lib.contains('pcre')) return 20;
      if (lib.contains('ffi')) return 21;
      if (lib.contains('jpeg')) return 30;
      if (lib.contains('png')) return 31;
      if (lib.contains('webp')) return 32;
      if (lib.contains('expat')) return 40;
      if (lib.contains('z')) return 50;
      return 100;
    }
    return getPriority(a).compareTo(getPriority(b));
  }

  /// Generate CMakeLists.txt
  String generateCMakeLists() {
    final libNameUpper = libName.toUpperCase();
    final includeList = includeDirs.map((d) => '    \${${libNameUpper}_ROOT}/$d').join('\n');
    final libList = staticLibs.map((l) => '    \${${libNameUpper}_ROOT}/lib/$l').join('\n');

    return '''
# $libName Android CMake Configuration
# Auto-generated, do not edit manually
#
# Usage:
#   include(\${CMAKE_SOURCE_DIR}/path/to/this/CMakeLists.txt)
#   target_link_libraries(your-lib $libName)

cmake_minimum_required(VERSION 3.18)

# Set library root directory
get_filename_component(${libNameUpper}_ROOT "\${CMAKE_CURRENT_LIST_DIR}/\${ANDROID_ABI}" ABSOLUTE)

# Check if path exists
if(NOT EXISTS "\${${libNameUpper}_ROOT}")
    message(FATAL_ERROR "$libName not found at: \${${libNameUpper}_ROOT}")
endif()

# Include directories
set(${libNameUpper}_INCLUDE_DIRS
$includeList
)

# Static libraries
set(${libNameUpper}_LIBRARIES
$libList
)

# Create IMPORTED library target
add_library($libName INTERFACE)

target_include_directories($libName INTERFACE \${${libNameUpper}_INCLUDE_DIRS})
target_link_libraries($libName INTERFACE \${${libNameUpper}_LIBRARIES})

# Android system library dependencies
target_link_libraries($libName INTERFACE
    log
    android
    m
)

# Export variables
set(${libNameUpper}_FOUND TRUE)

message(STATUS "Found $libName: \${${libNameUpper}_ROOT}")
''';
  }

  /// Generate INSTALL.md (English)
  String generateInstallMd() {
    final libsList = staticLibs.join('\n');

    return '''
# $libName Android Integration Guide

## Directory Structure

```text
android/
├── CMakeLists.txt      # CMake configuration
├── INSTALL.md          # This document
├── INSTALL_CN.md       # Chinese documentation
├── arm64-v8a/
│   ├── include/        # Header files
│   └── lib/            # Static libraries
├── armeabi-v7a/
│   ├── include/        # Header files
│   └── lib/            # Static libraries
├── x86/
│   ├── include/        # Header files
│   └── lib/            # Static libraries
├── x86_64/
│   ├── include/        # Header files
│   └── lib/            # Static libraries
```

## Integration Steps

### 1. Copy to Project

Copy the `android` directory to your Android project:

```text
your-project/
├── app/
│   └── src/main/cpp/
│       └── CMakeLists.txt
└── libs/
    └── $libName/
        └── android/      # Copy here
```

### 2. Modify build.gradle.kts

```kotlin
android {
    defaultConfig {
        // Set supported ABIs
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86", "x86_64")
        }
    }

    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
        }
    }
}
```

### 3. Modify CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.18)
project("your-app")

# Include $libName
include(\${CMAKE_SOURCE_DIR}/../../../libs/$libName/android/CMakeLists.txt)

# Your native library
add_library(your-native-lib SHARED native-lib.cpp)

# Link $libName
target_link_libraries(your-native-lib
    $libName
    log
)
```

## Included Libraries

```text
$libsList
```

## Notes

1. **API Level**: Ensure your `minSdk` is compatible with the API level used during compilation
2. **Static Linking**: All libraries are statically linked, which increases APK size
3. **ABI Support**: Only compiled ABIs are included. Missing ABIs need to be recompiled
''';
  }

  /// Generate INSTALL_CN.md (Chinese)
  String generateInstallCnMd() {
    final libsList = staticLibs.join('\n');

    return '''
# $libName Android 集成指南

## 目录结构

```text
android/
├── CMakeLists.txt      # CMake 配置文件
├── INSTALL.md          # 英文文档
├── INSTALL_CN.md       # 本文档
├── arm64-v8a/
│   ├── include/        # 头文件
│   └── lib/            # 静态库
├── armeabi-v7a/
│   ├── include/        # 头文件
│   └── lib/            # 静态库
├── x86/
│   ├── include/        # 头文件
│   └── lib/            # 静态库
├── x86_64/
│   ├── include/        # 头文件
│   └── lib/            # 静态库
```

## 集成步骤

### 1. 复制到项目

将 `android` 目录复制到你的 Android 项目中：

```text
your-project/
├── app/
│   └── src/main/cpp/
│       └── CMakeLists.txt
└── libs/
    └── $libName/
        └── android/      # 复制到这里
```

### 2. 修改 build.gradle.kts

```kotlin
android {
    defaultConfig {
        // 设置支持的 ABI
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86", "x86_64")
        }
    }

    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
        }
    }
}
```

### 3. 修改 CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.18)
project("your-app")

# 引入 $libName
include(\${CMAKE_SOURCE_DIR}/../../../libs/$libName/android/CMakeLists.txt)

# 你的 native 库
add_library(your-native-lib SHARED native-lib.cpp)

# 链接 $libName
target_link_libraries(your-native-lib
    $libName
    log
)
```

## 包含的库

```text
$libsList
```

## 注意事项

1. **API Level**: 请确保你的 `minSdk` 与编译时使用的 API level 兼容
2. **静态链接**: 所有库都是静态链接的，会增加 APK 体积
3. **ABI 支持**: 只包含已编译的 ABI，缺少的 ABI 需要重新编译
''';
  }

  /// Write files
  void generate() {
    final androidDir = join(installDir, 'android');

    // Check if android directory exists
    if (!Directory(androidDir).existsSync()) {
      return;
    }

    // Write CMakeLists.txt
    final cmakeFile = File(join(androidDir, 'CMakeLists.txt'));
    cmakeFile.writeAsStringSync(generateCMakeLists());

    // Write INSTALL.md (English)
    final installMdFile = File(join(androidDir, 'INSTALL.md'));
    installMdFile.writeAsStringSync(generateInstallMd());

    // Write INSTALL_CN.md (Chinese)
    final installCnMdFile = File(join(androidDir, 'INSTALL_CN.md'));
    installCnMdFile.writeAsStringSync(generateInstallCnMd());
  }
}
