import 'package:compile/compile.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

mixin ConfigType {
  String get value;
}

enum LibType with ConfigType {
  cAutotools('autotools'),
  cCmake('cmake'),
  cMeson('meson'),
  ;

  const LibType(
    this.value,
  );

  @override
  final String value;

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

  late final YamlList? _precompile = map['precompile'];

  late List<String> precompile =
      _precompile == null ? [] : _precompile!.whereType<String>().toList();

  late String name = map['name'];

  late String projectDirPath = normalize(absolute(projectDir.path));
  late String sourcePath = join(projectDirPath, 'source', name);
  late String? subpath = sourceMap['subpath'];
  late String workingPath =
      subpath == null ? sourcePath : normalize(join(sourcePath, subpath!));

  late final String? _licensePath = map['license'];

  late String? licensePath = _licensePath == null
      ? null
      : normalize(absolute(join(sourcePath, _licensePath!)));
  late String buildPath = join(projectDirPath, 'build');

  late String installPath = join(projectDirPath, 'install');

  LibType get type {
    final type = map['type'];
    return LibType.fromValue(type);
  }

  Lib.fromMap(this.map, this.projectDir) {
    analyze();
  }

  factory Lib.fromYaml(String yaml, Directory projectDir) {
    final map = loadYaml(yaml);
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
    final Map source = map['source'];
    final targetDirPath = sourcePath;

    if (targetDirPath.directory().existsSync()) {
      logger.i('Already downloaded $name in $targetDirPath');
      return;
    }

    if (source.containsKey('git')) {
      await downloadGit(targetDirPath, gitSource);
    } else if (source.containsKey('path')) {
      final String path = source['path'];
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
