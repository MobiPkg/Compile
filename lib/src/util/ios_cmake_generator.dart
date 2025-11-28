import 'dart:io';

import 'package:path/path.dart';

/// iOS CMake configuration generator
/// Generates CMake config files and INSTALL.md after workspace compilation
class IosCmakeGenerator {
  final String installDir;
  final String libName;
  final List<String> staticLibs;
  final List<String> includeDirs;
  final List<String> frameworks;

  IosCmakeGenerator({
    required this.installDir,
    required this.libName,
    required this.staticLibs,
    required this.includeDirs,
    this.frameworks = const [],
  });

  /// Scan install directory and create generator
  factory IosCmakeGenerator.fromInstallDir(String installDir, String libName) {
    final staticLibs = <String>[];
    final includeDirs = <String>[];

    // Scan iOS directory
    final iosDir = Directory(join(installDir, 'ios'));
    if (iosDir.existsSync()) {
      // Get first architecture directory to scan library files
      final archDirs = iosDir
          .listSync()
          .whereType<Directory>()
          .where((d) => !basename(d.path).startsWith('.'))
          .toList();

      if (archDirs.isNotEmpty) {
        final firstArch = archDirs.first;
        final libDir = Directory(join(firstArch.path, 'lib'));
        if (libDir.existsSync()) {
          // Scan all .a files
          for (final entity in libDir.listSync()) {
            if (entity is File && entity.path.endsWith('.a')) {
              final fileName = basename(entity.path);
              if (!staticLibs.contains(fileName)) {
                staticLibs.add(fileName);
              }
            }
          }
          // Sort by dependency order
          staticLibs.sort(_compareLibOrder);
        }

        // Scan include directory
        final includeDir = Directory(join(firstArch.path, 'include'));
        if (includeDir.existsSync()) {
          includeDirs.add('include');
          // Scan all subdirectories
          for (final entity in includeDir.listSync()) {
            if (entity is Directory) {
              includeDirs.add('include/${basename(entity.path)}');
            }
          }
        }

        // Check glib special include path
        final glibConfigDir =
            Directory(join(firstArch.path, 'lib', 'glib-2.0', 'include'));
        if (glibConfigDir.existsSync()) {
          includeDirs.add('lib/glib-2.0/include');
        }
      }
    }

    return IosCmakeGenerator(
      installDir: installDir,
      libName: libName,
      staticLibs: staticLibs,
      includeDirs: includeDirs,
    );
  }

  /// Library sort comparison function
  static int _compareLibOrder(String a, String b) {
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
    final includeList =
        includeDirs.map((d) => '    \${${libNameUpper}_ROOT}/$d').join('\n');
    final libList = staticLibs
        .map((l) => '    \${${libNameUpper}_ROOT}/lib/$l')
        .join('\n');

    return '''
# $libName iOS CMake Configuration
# Auto-generated, do not edit manually
#
# Usage:
#   include(\${CMAKE_SOURCE_DIR}/path/to/this/CMakeLists.txt)
#   target_link_libraries(your-lib $libName)

cmake_minimum_required(VERSION 3.18)

# Set library root directory based on architecture
if(CMAKE_OSX_ARCHITECTURES STREQUAL "arm64")
    set(IOS_ARCH "arm64")
elseif(CMAKE_OSX_ARCHITECTURES STREQUAL "x86_64")
    set(IOS_ARCH "x86_64-simulator")
else()
    # Default to universal if available
    if(EXISTS "\${CMAKE_CURRENT_LIST_DIR}/universal")
        set(IOS_ARCH "universal")
    else()
        set(IOS_ARCH "arm64")
    endif()
endif()

get_filename_component(${libNameUpper}_ROOT "\${CMAKE_CURRENT_LIST_DIR}/\${IOS_ARCH}" ABSOLUTE)

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

# iOS system framework dependencies
target_link_libraries($libName INTERFACE
    "-framework Foundation"
    "-framework CoreFoundation"
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
# $libName iOS Integration Guide

## Directory Structure

```text
ios/
├── CMakeLists.txt      # CMake configuration
├── INSTALL.md          # This document
├── INSTALL_CN.md       # Chinese documentation
├── arm64/
│   ├── include/        # Header files
│   └── lib/            # Static libraries
├── x86_64-simulator/
│   ├── include/        # Header files
│   └── lib/            # Static libraries
├── universal/
│   ├── include/        # Header files
│   └── lib/            # Universal static libraries (arm64 + x86_64)
```

## Integration Steps

### Option 1: Using XCFramework (Recommended)

If an XCFramework is available, simply drag it into your Xcode project.

### Option 2: Using CMake

#### 1. Copy to Project

Copy the `ios` directory to your iOS project:

```text
your-project/
├── YourApp/
│   └── ...
└── libs/
    └── $libName/
        └── ios/      # Copy here
```

#### 2. Add to Xcode Project

1. Add the static libraries (.a files) to your target
2. Add the include directories to Header Search Paths
3. Add required frameworks to Link Binary With Libraries

### Option 3: Using CocoaPods

Create a podspec file for local integration.

## Included Libraries

```text
$libsList
```

## Notes

1. **Architecture**: Make sure to use the correct architecture for your target (arm64 for device, x86_64 for simulator)
2. **Universal Libraries**: If available, universal libraries contain both architectures
3. **Bitcode**: These libraries may not include bitcode. Disable bitcode in your project if needed
''';
  }

  /// Generate INSTALL_CN.md (Chinese)
  String generateInstallCnMd() {
    final libsList = staticLibs.join('\n');

    return '''
# $libName iOS 集成指南

## 目录结构

```text
ios/
├── CMakeLists.txt      # CMake 配置文件
├── INSTALL.md          # 英文文档
├── INSTALL_CN.md       # 本文档
├── arm64/
│   ├── include/        # 头文件
│   └── lib/            # 静态库
├── x86_64-simulator/
│   ├── include/        # 头文件
│   └── lib/            # 静态库
├── universal/
│   ├── include/        # 头文件
│   └── lib/            # 通用静态库 (arm64 + x86_64)
```

## 集成步骤

### 方式一：使用 XCFramework（推荐）

如果有 XCFramework 可用，直接拖入 Xcode 项目即可。

### 方式二：使用 CMake

#### 1. 复制到项目

将 `ios` 目录复制到你的 iOS 项目中：

```text
your-project/
├── YourApp/
│   └── ...
└── libs/
    └── $libName/
        └── ios/      # 复制到这里
```

#### 2. 添加到 Xcode 项目

1. 将静态库 (.a 文件) 添加到你的 target
2. 将 include 目录添加到 Header Search Paths
3. 将所需的 frameworks 添加到 Link Binary With Libraries

### 方式三：使用 CocoaPods

创建一个 podspec 文件进行本地集成。

## 包含的库

```text
$libsList
```

## 注意事项

1. **架构**: 确保使用正确的架构（arm64 用于真机，x86_64 用于模拟器）
2. **通用库**: 如果可用，通用库包含两种架构
3. **Bitcode**: 这些库可能不包含 bitcode，如需要请在项目中禁用 bitcode
''';
  }

  /// Write files
  void generate() {
    final iosDir = join(installDir, 'ios');

    // Check if ios directory exists
    if (!Directory(iosDir).existsSync()) {
      return;
    }

    // Write CMakeLists.txt
    final cmakeFile = File(join(iosDir, 'CMakeLists.txt'));
    cmakeFile.writeAsStringSync(generateCMakeLists());

    // Write INSTALL.md (English)
    final installMdFile = File(join(iosDir, 'INSTALL.md'));
    installMdFile.writeAsStringSync(generateInstallMd());

    // Write INSTALL_CN.md (Chinese)
    final installCnMdFile = File(join(iosDir, 'INSTALL_CN.md'));
    installCnMdFile.writeAsStringSync(generateInstallCnMd());
  }
}
