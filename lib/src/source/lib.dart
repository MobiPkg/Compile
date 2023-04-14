import 'package:compile/compile.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

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
  cMeson('meson', hide: true),
  ;

  const LibType(
    this.value, {
    this.defaultOptions = const [],
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

class Lib
    with
        LogMixin,
        LibSourceMixin,
        LibCheckMixin,
        LibDownloadMixin,
        LibFlagsMixin {
  @override
  final Map map;
  final Directory projectDir;

  late final _precompile = map['precompile'] as YamlList?;

  late List<String> precompile =
      _precompile == null ? [] : _precompile!.whereType<String>().toList();

  late String name = map['name'] as String;

  late String projectDirPath = normalize(absolute(projectDir.path));
  late String sourcePath = join(projectDirPath, 'source', name);
  late String shellPath = join(projectDirPath, 'source', 'shell');
  late String? subpath = sourceMap['subpath'] as String?;
  late String workingPath =
      subpath == null ? sourcePath : normalize(join(sourcePath, subpath));

  late final String? _licensePath = map['license'] as String?;

  late String? licensePath = _licensePath == null
      ? null
      : normalize(absolute(join(sourcePath, _licensePath)));
  late String buildPath = join(projectDirPath, 'build');

  String get installPath {
    return envs.prefix ?? join(projectDirPath, 'install');
  }

  LibType? _type;

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

    logger.warning(logBuffer.toString().trim());
    throw Exception('Not found type, guest failed.');
  }

  Lib.fromMap(this.map, this.projectDir) {
    analyze();
  }

  factory Lib.fromYaml(String yaml, Directory projectDir) {
    final map = loadYaml(yaml) as Map;
    return Lib.fromMap(map, projectDir);
  }

  factory Lib.fromDir(Directory projectDir) {
    final fileNames = [
      'lib.yaml',
      'lib.yml',
    ];
    final file = projectDir.getFirstMatchFile(fileNames);
    if (file == null) {
      throw Exception('Not found ${fileNames.join('|')} in ${projectDir.path}');
    }
    return Lib.fromYaml(file.readAsStringSync(), projectDir);
  }

  Future<void> download() async {
    final Map source = map['source'] as Map;
    final targetDirPath = sourcePath;

    if (targetDirPath.directory().existsSync()) {
      logger.i('Already downloaded $name in $targetDirPath');
      return;
    }

    if (source.containsKey('git')) {
      await downloadGit(targetDirPath, gitSource);
    } else if (source.containsKey('path')) {
      final String path = source['path'] as String;
      final sourcePath = normalize(absolute(path));
      final sourceDir = Directory(sourcePath);
      if (!sourceDir.existsSync()) {
        throw Exception('Not found source directory $sourcePath');
      }
      await copyPath(targetDirPath, pathSource);
    } else if (source.containsKey('http')) {
      await downloadAndExtractHttp(targetDirPath, httpSource);
    } else {
      throw Exception('Not support source type');
    }
  }

  Future<void> removeOldSource() async {
    final dir = sourcePath.directory();
    if (dir.existsSync()) {
      logger.i('Remove old source: ${dir.absolute.path}');
      dir.deleteSync(recursive: true);
    }
  }

  Future<void> removeOldBuild() async {
    final dir = buildPath.directory();
    if (dir.existsSync()) {
      logger.i('Remove old build: ${dir.absolute.path}');
      dir.deleteSync(recursive: true);
    }
  }
}
