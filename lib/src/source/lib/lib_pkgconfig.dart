import 'dart:io';

import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

/// pkg-config 文件配置
/// 
/// 在 lib.yaml 中配置:
/// ```yaml
/// pkgconfig:
///   - name: zlib
///     description: zlib compression library
///     version: 1.3.1
///     libs: -lz
///     cflags: ""
/// ```
class PkgConfigItem {
  final String name;
  final String description;
  final String version;
  final String libs;
  final String cflags;
  final List<String> requires;

  PkgConfigItem({
    required this.name,
    required this.description,
    required this.version,
    required this.libs,
    this.cflags = '',
    this.requires = const [],
  });

  factory PkgConfigItem.fromMap(Map map) {
    final requiresList = map['requires'];
    List<String> requires = [];
    if (requiresList is YamlList) {
      requires = requiresList.whereType<String>().toList();
    } else if (requiresList is String) {
      requires = [requiresList];
    }

    return PkgConfigItem(
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      version: map['version'] as String? ?? '',
      libs: map['libs'] as String? ?? '',
      cflags: map['cflags'] as String? ?? '',
      requires: requires,
    );
  }

  /// 生成 .pc 文件内容
  String generateContent(String prefix) {
    final buffer = StringBuffer();
    buffer.writeln('prefix=$prefix');
    buffer.writeln(r'exec_prefix=${prefix}');
    buffer.writeln(r'libdir=${exec_prefix}/lib');
    buffer.writeln(r'includedir=${prefix}/include');
    buffer.writeln();
    buffer.writeln('Name: $name');
    buffer.writeln('Description: $description');
    buffer.writeln('Version: $version');
    if (requires.isNotEmpty) {
      buffer.writeln('Requires: ${requires.join(' ')}');
    }
    if (libs.isNotEmpty) {
      buffer.writeln('Libs: -L\${libdir} $libs');
    }
    if (cflags.isNotEmpty) {
      buffer.writeln('Cflags: -I\${includedir} $cflags');
    } else {
      buffer.writeln(r'Cflags: -I${includedir}');
    }
    return buffer.toString();
  }

  /// 写入 .pc 文件
  Future<void> writeToFile(String prefix) async {
    final pkgConfigDir = join(prefix, 'lib', 'pkgconfig');
    final pcFile = File(join(pkgConfigDir, '$name.pc'));
    
    if (pcFile.existsSync()) {
      return; // 已存在，不覆盖
    }
    
    await Directory(pkgConfigDir).create(recursive: true);
    await pcFile.writeAsString(generateContent(prefix));
  }
}

/// Lib 的 pkg-config 配置 mixin
mixin LibPkgConfigMixin {
  Map get map;

  /// 获取需要生成的 pkg-config 配置列表
  late final List<PkgConfigItem> pkgConfigItems = _parsePkgConfigItems();

  List<PkgConfigItem> _parsePkgConfigItems() {
    final pkgconfig = map['pkgconfig'];
    if (pkgconfig == null) {
      return [];
    }

    if (pkgconfig is YamlList) {
      return pkgconfig
          .whereType<Map>()
          .map((e) => PkgConfigItem.fromMap(e))
          .toList();
    }

    return [];
  }

  /// 是否有需要生成的 pkg-config 文件
  bool get hasPkgConfig => pkgConfigItems.isNotEmpty;

  /// 生成所有配置的 pkg-config 文件
  Future<void> generatePkgConfigFiles(String installPrefix) async {
    for (final item in pkgConfigItems) {
      await item.writeToFile(installPrefix);
    }
  }
}
