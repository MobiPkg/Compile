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

  void _addFlagsToEnv(Map<String, String> env, String key, String value) {
    if (value.isNotEmpty) {
      final oldValue = env[key];
      env[key] = oldValue == null ? value : '$oldValue $value';
    }
  }

  void injectEnv(Map<String, String> env) {
    _addFlagsToEnv(env, 'CFLAGS', cFlags);
    _addFlagsToEnv(env, 'CPPFLAGS', cppFlags);
    _addFlagsToEnv(env, 'CXXFLAGS', cxxFlags);
    _addFlagsToEnv(env, 'LDFLAGS', ldFlags);
  }

  void injectPrefix(
    Map<String, String> env,
    String depPrefix,
    CpuType cpuType,
  ) {
    String? prefix;

    if (depPrefix.trim().isNotEmpty) {
      prefix = depPrefix;
    } else {
      prefix = envs.prefix;
    }

    if (prefix != null) {
      _addFlagsToEnv(env, 'CFLAGS', '-I$prefix/include');
      _addFlagsToEnv(env, 'CXXFLAGS', '-I$prefix/include');
      _addFlagsToEnv(env, 'LDFLAGS', '-L$prefix/lib');
    }
  }

  void addFlagsToCmakeArgs(Map<String, String> args) {
    void add(String key, String value) {
      if (value.isNotEmpty) {
        final src = args[key];
        args[key] = src == null ? value : '$src $value';
      }
    }

    add('CMAKE_C_FLAGS_RELEASE', cFlags);
    add('CMAKE_CXX_FLAGS_RELEASE', cxxFlags);
    add('CMAKE_EXE_LINKER_FLAGS_RELEASE', ldFlags);
  }

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
