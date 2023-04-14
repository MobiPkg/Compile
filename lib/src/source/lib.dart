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

  LibType get type {
    final type = map['type'] as String;
    return LibType.fromValue(type);
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
