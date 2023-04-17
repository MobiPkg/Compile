import 'package:compile/compile.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

class Project {
  final Map map;
  final Directory projectDir;

  Project._(this.map, this.projectDir);

  List<Lib> libs() {
    final libs = <Lib>[];
    final list = map['libs'] as List;

    for (final item in list) {
      final map = item as Map;

      final path = map['path'];

      if (path is! String) {
        throw Exception('The lib item must have path string value.');
      }

      final libDir = join(projectDir.path, path).directory();
      if (!libDir.existsSync()) {
        throw Exception('The lib dir not exists: $libDir');
      }
      libs.add(Lib.fromDir(libDir));
    }

    return libs;
  }

  static Project fromDirPath(String dirPath) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      throw Exception('Project dir not exists: $dirPath');
    }

    final matchFiles = [
      'project.yaml',
      'project.yml',
    ];

    for (final matchFile in matchFiles) {
      final file = File(join(dirPath, matchFile));
      if (file.existsSync()) {
        final map = loadYaml(file.readAsStringSync()) as Map;
        return Project._(map, dir);
      }
    }

    throw Exception('Not found project yaml file in $dirPath. '
        'Match files: ${matchFiles.join(', ')}');
  }
}
