import 'package:yaml/yaml.dart';

/// Lib 的额外产物库配置 mixin
/// 
/// 某些库在编译后会产生多个静态库文件，例如 libwebp 会产生：
/// - libwebp.a (主库)
/// - libwebpmux.a (mux 库)
/// - libwebpdemux.a (demux 库)
/// - libsharpyuv.a (私有依赖)
/// 
/// 在 lib.yaml 中配置:
/// ```yaml
/// extra_libs:
///   - libwebpmux
///   - libwebpdemux
///   - libsharpyuv
/// ```
/// 
/// 这些额外库会在打包 XCFramework 时被包含。
mixin LibExtraMixin {
  Map get map;

  /// 获取额外产物库列表
  late final List<String> extraLibs = _parseExtraLibs();

  List<String> _parseExtraLibs() {
    final value = map['extra_libs'];
    if (value == null) {
      return [];
    }

    if (value is YamlList) {
      return value.whereType<String>().toList();
    }

    if (value is List) {
      return value.whereType<String>().toList();
    }

    return [];
  }

  /// 是否有额外产物库
  bool get hasExtraLibs => extraLibs.isNotEmpty;

  /// 获取所有库名称（包括主库和额外库）
  /// [mainLibName] 主库名称
  List<String> getAllLibNames(String mainLibName) {
    return [mainLibName, ...extraLibs];
  }
}
