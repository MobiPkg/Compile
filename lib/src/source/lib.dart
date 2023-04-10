import 'package:compile/compile.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

mixin ConfigType {
  String get value;
}

enum LibType with ConfigType {
  cAutotools('autotools'),
  cCmake('cmake'),
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

class Lib with LogMixin, LibSourceMixin, LibCheckMixin, LibDownloadMixin {
  @override
  final Map map;
  final Directory projectDir;

  late String name = map['name'];

  late String projectDirPath = normalize(absolute(projectDir.path));
  late String sourcePath = join(projectDirPath, 'source', name);
  late String? subpath = sourceMap['subpath'];
  late String workingPath =
      subpath == null ? sourcePath : join(sourcePath, subpath!);

  late String licensePath = join(sourcePath, map['license']);
  late String installPath = join(projectDirPath, 'install');
  late String buildPath = join(projectDirPath, 'build');

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
    final lib = File(join(projectDir.path, 'lib.yaml'));
    if (!lib.existsSync()) {
      throw Exception('Not found lib.yaml in ${projectDir.path}');
    }
    final file = File(lib.path);
    return Lib.fromYaml(file.readAsStringSync(), projectDir);
  }

  Future<void> download() async {
    final Map source = map['source'];
    final targetDirPath = sourcePath;

    if (targetDirPath.directory().existsSync()) {
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
      dir.deleteSync(recursive: true);
    }
  }
}
