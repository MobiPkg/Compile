import 'package:yaml/yaml.dart';

/// 钩子条目，支持条件过滤
class HookEntry {
  /// 脚本内容
  final String script;
  
  /// 平台过滤 (ios, android, harmony)
  final List<String>? platforms;
  
  /// 架构过滤 (arm64, arm64-simulator, x86_64, armv7, etc.)
  final List<String>? archs;

  HookEntry({
    required this.script,
    this.platforms,
    this.archs,
  });

  /// 从简单字符串创建（无条件）
  factory HookEntry.fromString(String script) {
    return HookEntry(script: script);
  }

  /// 从 Map 创建（带条件）
  factory HookEntry.fromMap(Map map) {
    final script = map['script'] as String? ?? map['run'] as String? ?? '';
    
    List<String>? platforms;
    final platformValue = map['platform'] ?? map['platforms'];
    if (platformValue is String) {
      platforms = [platformValue];
    } else if (platformValue is YamlList) {
      platforms = platformValue.whereType<String>().toList();
    } else if (platformValue is List) {
      platforms = platformValue.whereType<String>().toList();
    }
    
    List<String>? archs;
    final archValue = map['arch'] ?? map['archs'];
    if (archValue is String) {
      archs = [archValue];
    } else if (archValue is YamlList) {
      archs = archValue.whereType<String>().toList();
    } else if (archValue is List) {
      archs = archValue.whereType<String>().toList();
    }
    
    return HookEntry(
      script: script,
      platforms: platforms,
      archs: archs,
    );
  }

  /// 检查是否匹配当前平台和架构
  bool matches({String? platform, String? arch}) {
    // 如果没有设置过滤条件，则匹配所有
    if (platforms == null && archs == null) {
      return true;
    }
    
    // 检查平台
    if (platforms != null && platforms!.isNotEmpty) {
      if (platform == null || !platforms!.contains(platform)) {
        return false;
      }
    }
    
    // 检查架构
    if (archs != null && archs!.isNotEmpty) {
      if (arch == null || !archs!.contains(arch)) {
        return false;
      }
    }
    
    return true;
  }
}

/// Lib 的构建钩子配置 mixin
/// 
/// 支持在构建的不同阶段执行自定义脚本，可以按平台/架构过滤。
/// 
/// 在 lib.yaml 中配置:
/// ```yaml
/// hooks:
///   post_configure:
///     # 简单脚本（所有平台/架构都执行）
///     - echo "Configure completed"
///     
///     # 带条件的脚本
///     - script: |
///         echo "iOS only"
///       platform: ios
///     
///     # 多平台/架构条件
///     - script: |
///         echo "iOS arm64 only"
///       platforms: [ios]
///       archs: [arm64, arm64-simulator]
///   
///   post_build:
///     - echo "Build completed"
/// ```
/// 
/// 可用的钩子点：
/// - `post_configure`: configure 命令执行后
/// - `post_build`: make 命令执行后（安装前）
/// 
/// 条件过滤：
/// - `platform` / `platforms`: 平台过滤 (ios, android, harmony)
/// - `arch` / `archs`: 架构过滤 (arm64, arm64-simulator, x86_64, etc.)
/// 
/// 脚本中可用的环境变量：
/// - `SOURCE_DIR`: 源码目录
/// - `BUILD_DIR`: 构建目录
/// - `INSTALL_PREFIX`: 安装目录
/// - `HOST`: 目标主机三元组
/// - `ARCH`: CPU 架构
/// - `PLATFORM`: 平台名称
/// - `SDK`: SDK 名称 (iOS)
/// - `SDK_PATH`: SDK 路径 (iOS)
mixin LibHooksMixin {
  Map get map;

  /// 获取钩子配置
  late final Map<String, List<HookEntry>> hooks = _parseHooks();

  Map<String, List<HookEntry>> _parseHooks() {
    final hooksValue = map['hooks'];
    if (hooksValue == null) {
      return {};
    }

    if (hooksValue is! Map) {
      return {};
    }

    final result = <String, List<HookEntry>>{};
    
    for (final entry in hooksValue.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      
      final entries = <HookEntry>[];
      
      if (value is String) {
        entries.add(HookEntry.fromString(value));
      } else if (value is YamlList) {
        for (final item in value) {
          if (item is String) {
            entries.add(HookEntry.fromString(item));
          } else if (item is Map) {
            entries.add(HookEntry.fromMap(item));
          }
        }
      } else if (value is List) {
        for (final item in value) {
          if (item is String) {
            entries.add(HookEntry.fromString(item));
          } else if (item is Map) {
            entries.add(HookEntry.fromMap(item));
          }
        }
      }
      
      if (entries.isNotEmpty) {
        result[key] = entries;
      }
    }

    return result;
  }

  /// 获取 post_configure 钩子
  List<HookEntry> get postConfigureHookEntries => hooks['post_configure'] ?? [];

  /// 获取 post_build 钩子
  List<HookEntry> get postBuildHookEntries => hooks['post_build'] ?? [];

  /// 获取匹配当前平台/架构的 post_configure 钩子脚本
  List<String> getPostConfigureHooks({String? platform, String? arch}) {
    return postConfigureHookEntries
        .where((e) => e.matches(platform: platform, arch: arch))
        .map((e) => e.script)
        .toList();
  }

  /// 获取匹配当前平台/架构的 post_build 钩子脚本
  List<String> getPostBuildHooks({String? platform, String? arch}) {
    return postBuildHookEntries
        .where((e) => e.matches(platform: platform, arch: arch))
        .map((e) => e.script)
        .toList();
  }

  /// 是否有 post_configure 钩子（任意平台/架构）
  bool get hasPostConfigureHooks => postConfigureHookEntries.isNotEmpty;

  /// 是否有 post_build 钩子（任意平台/架构）
  bool get hasPostBuildHooks => postBuildHookEntries.isNotEmpty;

  /// 向后兼容：获取所有 post_configure 钩子脚本（不过滤）
  List<String> get postConfigureHooks => 
      postConfigureHookEntries.map((e) => e.script).toList();

  /// 向后兼容：获取所有 post_build 钩子脚本（不过滤）
  List<String> get postBuildHooks => 
      postBuildHookEntries.map((e) => e.script).toList();
}
