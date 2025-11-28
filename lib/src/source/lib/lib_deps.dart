import 'package:yaml/yaml.dart';

/// Lib 的依赖管理 mixin
/// 
/// 在 lib.yaml 中配置:
/// ```yaml
/// deps:
///   - glib
///   - zlib
///   - libpng
/// ```
mixin LibDepsMixin {
  Map get map;

  /// 获取依赖列表
  late final List<String> deps = _parseDeps();

  List<String> _parseDeps() {
    final depsValue = map['deps'];
    if (depsValue == null) {
      return [];
    }

    if (depsValue is YamlList) {
      return depsValue.whereType<String>().toList();
    }

    if (depsValue is List) {
      return depsValue.whereType<String>().toList();
    }

    return [];
  }

  /// 是否有依赖
  bool get hasDeps => deps.isNotEmpty;
}
