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
