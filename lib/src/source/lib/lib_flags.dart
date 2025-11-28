import 'package:compile/compile.dart';
import 'package:yaml/yaml.dart';

mixin LibFlagsMixin {
  Map get map;

  Map get flagsMap => map.getMap('flags');

  LibFlag get flags => LibFlag(
        flagsMap,
        martixItem: matrixItem,
      );

  String get cFlags => flags.c;
  String get cppFlags => flags.cpp;
  String get cxxFlags => flags.cxx;
  String get ldFlags => flags.ld;

  /// 获取通用 options
  List<String> get options {
    final result = <String>[];
    final opt = map['options'] as YamlList?;
    if (opt != null) {
      opt.whereType<String>().forEach(result.add);
    }
    if (matrixItem != null) {
      result.addAll(matrixItem!.options);
    }
    return result;
  }

  /// 获取 Android 特定的 options
  List<String> get androidOptions {
    final result = <String>[];
    final opt = map['android_options'] as YamlList?;
    if (opt != null) {
      opt.whereType<String>().forEach(result.add);
    }
    return result;
  }

  /// 获取 iOS 特定的 options
  List<String> get iosOptions {
    final result = <String>[];
    final opt = map['ios_options'] as YamlList?;
    if (opt != null) {
      opt.whereType<String>().forEach(result.add);
    }
    return result;
  }

  /// 获取 Harmony 特定的 options
  List<String> get harmonyOptions {
    final result = <String>[];
    final opt = map['harmony_options'] as YamlList?;
    if (opt != null) {
      opt.whereType<String>().forEach(result.add);
    }
    return result;
  }

  /// 根据平台获取合并后的 options
  List<String> getOptionsForPlatform(String platform) {
    final result = <String>[...options];
    switch (platform) {
      case 'android':
        result.addAll(androidOptions);
        break;
      case 'ios':
        result.addAll(iosOptions);
        break;
      case 'harmony':
        result.addAll(harmonyOptions);
        break;
    }
    return result;
  }

  /// 获取 Android 配置
  Map get androidConfig => map.getMap('android');

  /// 获取 Android minSdk（如果配置了的话）
  int? get androidMinSdk {
    final config = androidConfig;
    final minSdk = config['min_sdk'];
    if (minSdk is int) {
      return minSdk;
    }
    return null;
  }

  MatrixItem? matrixItem;

  List<MatrixItem> get matrixList {
    final list = map['matrix'];
    if (list == null) {
      return [];
    }
    if (list is! YamlList) {
      throw Exception('matrix must be a list');
    }
    final result = <MatrixItem>[];
    for (final item in list) {
      if (item is! YamlMap) {
        throw Exception('matrix item must be a map');
      }
      result.add(MatrixItem.fromMap(item));
    }
    return result;
  }
}

class LibFlag {
  final Map? map;
  final MatrixItem? martixItem;

  LibFlag(this.map, {this.martixItem});

  String get c => _value('c') + (martixItem?.flags.c ?? '');
  String get cpp => _value('cpp') + (martixItem?.flags.cpp ?? '');
  String get cxx => _value('cxx') + (martixItem?.flags.cxx ?? '');
  String get ld => _value('ld') + (martixItem?.flags.ld ?? '');

  String _value(String key) {
    final v = map?[key];
    if (v == null) {
      return '';
    }
    if (v is! String) {
      throw Exception('LibFlag value must be a string, but $key is $v');
    }
    return v;
  }
}

class MatrixItem {
  final List<String> options;
  final LibFlag flags;

  MatrixItem(this.options, this.flags);

  factory MatrixItem.fromMap(Map map) {
    final flagMap = map['flags'];
    LibFlag flags;
    if (flagMap == null || flagMap is Map) {
      flags = LibFlag(flagMap as Map?);
    } else {
      throw Exception('MartixItem flags must be a map');
    }

    final List? opt = map['options'] as YamlList?;
    final options = <String>[];

    for (final item in opt ?? []) {
      if (item is String) {
        options.add(item);
      }
    }

    return MatrixItem(options, flags);
  }
}
