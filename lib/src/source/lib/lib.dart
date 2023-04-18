import 'package:compile/compile.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

class Lib
    with
        LogMixin,
        LibSourceMixin,
        LibCheckMixin,
        LibDownloadMixin,
        LibFlagsMixin,
        LibTypeMixin,
        LibPatchMixin {
  @override
  final Map map;

  @override
  final Directory libDir;

  late final _precompile = map['precompile'] as YamlList?;

  late List<String> precompile =
      _precompile == null ? [] : _precompile!.whereType<String>().toList();

  late String name = map['name'] as String;

  late String libDirPath = normalize(absolute(libDir.path));
  late String sourcePath = join(libDirPath, 'source', name);
  late String shellPath = join(libDirPath, 'source', 'shell');
  late String toolchainPath = join(libDirPath, 'source', 'toolchain');
  late String? subpath = sourceMap['subpath'] as String?;

  @override
  late String workingPath =
      subpath == null ? sourcePath : normalize(join(sourcePath, subpath));

  late final String? _licensePath = map['license'] as String?;

  late String? licensePath = _licensePath == null
      ? null
      : normalize(absolute(join(sourcePath, _licensePath)));
  late String buildPath = join(libDirPath, 'build');

  String get installPath {
    return envs.prefix ?? join(libDirPath, 'install');
  }

  Lib.fromMap(this.map, this.libDir) {
    analyze();
  }

  factory Lib.fromYaml(String yaml, Directory libDir) {
    final map = loadYaml(yaml) as Map;
    return Lib.fromMap(map, libDir);
  }

  factory Lib.fromDir(Directory libDir) {
    final fileNames = [
      'lib.yaml',
      'lib.yml',
    ];
    final file = libDir.getFirstMatchFile(fileNames);
    if (file == null) {
      throw Exception('Not found ${fileNames.join('|')} in ${libDir.path}');
    }
    return Lib.fromYaml(file.readAsStringSync(), libDir);
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
