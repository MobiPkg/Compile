import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:yaml/yaml.dart';

class Lib {
  final Map map;

  Lib.fromMap(this.map);

  String get name => map['name'];

  factory Lib.fromYaml(String yaml) {
    final map = loadYaml(yaml);
    return Lib.fromMap(map);
  }

  factory Lib.fromFile(File file) {
    return Lib.fromYaml(file.readAsStringSync());
  }

  Future<void> download(String projectDir) async {
    final Map source = map['source'];
    final targetDirPath = join(projectDir, name);
    final targetDir = Directory(targetDirPath);
    if (targetDir.existsSync()) {
      print(
        'The source directory $targetDirPath already exists, '
        'skip download',
      );
      return;
    }
    if (source.containsKey('git')) {
      final String gitUrl = source['git'];
      final cmd = 'git clone $gitUrl $name';
      await run(cmd);
    } else if (source.containsKey('path')) {
      final String path = source['path'];
      final sourcePath = normalize(absolute(path));
      final sourceDir = Directory(sourcePath);
      if (!sourceDir.existsSync()) {
        throw Exception('Not found source directory $sourcePath');
      }
      print('copy $sourcePath to $targetDirPath');
      await run('cp -r $sourcePath $targetDirPath');
    } else if (source.containsKey('http')) {
      final String httpUrl = source['http'];
      await _downloadHttp(httpUrl);
    } else {
      throw Exception('Not support source type');
    }
  }

  Future<void> _downloadHttp(String url) async {
    final dio = Dio();
    final response = await dio.getUri(Uri.parse(url));
    //
  }
}
