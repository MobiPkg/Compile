import 'package:compile/compile.dart';
import 'package:path/path.dart';

mixin ConfigType {
  String get value;
}

enum LibType with ConfigType {
  cAutotools(
    'autotools',
    defaultOptions: [
      '--enable-static',
      '--enable-shared',
    ],
    aliases: [
      'at',
    ],
  ),
  cCmake(
    'cmake',
    aliases: ['cm'],
  ),
  cMeson('meson'),
  cMakefile('makefile', hide: true),
  rust('rust', hide: true),
  ;

  const LibType(
    this.value, {
    this.defaultOptions = const [],
    // ignore: unused_element
    this.hide = false,
    this.aliases = const [],
  });

  @override
  final String value;

  final List<String> defaultOptions;

  final List<String> aliases;

  final bool hide;

  static LibType fromValue(String value) {
    for (final type in values) {
      if (type.value == value) {
        return type;
      }
    }
    throw Exception('Not support type: $value');
  }
}

mixin LibTypeMixin {
  Map get map;

  LibType? _type;

  String get workingPath;

  LibType get type {
    if (_type != null) {
      return _type!;
    }
    final logBuffer = StringBuffer();
    final type = map['type'] as String?;
    if (type != null) {
      try {
        logBuffer.writeln('Found type: $type');
        _type = LibType.fromValue(type);
        logBuffer.writeln('Support type: $type, will use it');
        logger.info(logBuffer.toString().trim());
        return _type!;
      } catch (e) {
        logBuffer.writeln('Not support type: $type, will guest by source');
      }
    }

    // guest type by source
    final dir = workingPath.directory();
    if (!dir.existsSync()) {
      logger.warning(logBuffer.toString().trim());
      throw Exception('Not found $workingPath, guest type failed');
    }

    final pathList =
        dir.listSync().map((e) => basename(e.path).toLowerCase()).toList();
    // guest by cmake
    for (final name in pathList) {
      if (name == 'cmakelists.txt') {
        logBuffer.writeln('Found $name, will use cmake');
        logger.info(logBuffer.toString().trim());
        _type = LibType.cCmake;
        return _type!;
      }
    }

    // guest for meson
    for (final name in pathList) {
      if (name == 'meson.build') {
        logBuffer.writeln('Found $name, will use meson');
        logger.info(logBuffer.toString().trim());
        _type = LibType.cMeson;
        return _type!;
      }
    }

    // guest for autotools
    for (final name in pathList) {
      const guestFiles = [
        'configure',
        'autogen.sh',
        'configure.ac',
        'configure.in',
        'makefile.am',
        'makefile.in',
      ];
      if (guestFiles.contains(name)) {
        logBuffer.writeln('Found $name, will use autotools');
        logger.info(logBuffer.toString().trim());
        _type = LibType.cAutotools;
        return _type!;
      }
    }

    // guest for makefile
    for (final name in pathList) {
      if (name == 'makefile') {
        logBuffer.writeln('Found $name, will use makefile');
        logger.info(logBuffer.toString().trim());
        _type = LibType.cMakefile;
        return _type!;
      }
    }

    // guest for rust
    for (final name in pathList) {
      if (name == 'cargo.toml') {
        logBuffer.writeln('Found $name, will use rust');
        logger.info(logBuffer.toString().trim());
        _type = LibType.rust;
        return _type!;
      }
    }

    logger.warning(logBuffer.toString().trim());
    throw Exception('Not found type, guest failed in $workingPath .');
  }
}
