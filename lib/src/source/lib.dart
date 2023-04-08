import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:yaml/yaml.dart';

class Lib {
  final Map map;
  final Directory projectDir;

  late String name = map['name'];

  late String projectDirPath = normalize(absolute(projectDir.path));
  late String sourcePath = join(projectDirPath, 'source', name);
  late String licensePath = join(sourcePath, map['license']);
  late String installPath = join(projectDirPath, 'install');
  late String buildPath = join(projectDirPath, 'build', name);

  Lib.fromMap(this.map, this.projectDir) {
    analyze();
  }

  void _throwError(String message) {
    throw Exception(message);
  }

  void analyze() {
    final source = map['source'];
    if (source == null) {
      throw Exception('Not found source in lib.yaml');
    }
    if (source['git'] != null) {
      final git = source['git'];
      if (git is! String) {
        _throwError('git is must be string.');
      }
      final ref = source['ref'];
      if (ref != null && ref is! String) {
        _throwError('ref is must be string.');
      }
    } else if (source['path'] != null) {
      final path = source['path'];
      if (path is! String) {
        _throwError('path is must be string.');
      }
      if (!FileSystemEntity.isDirectorySync(path)) {
        _throwError('path is must be directory.');
      }
    } else if (source['http'] != null) {
      final http = source['http'];
      if (http is! String) {
        _throwError('http is must be string.');
      }
      final uri = Uri.parse(http);
      if (uri.scheme != 'http' && uri.scheme != 'https') {
        _throwError('http is must be http or https.');
      }
    } else {
      throw Exception('Not support source type');
    }
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
    if (source.containsKey('git')) {
      final String gitUrl = source['git'];
      final ref = source['ref'];
      await _handleGit(
        targetDir: targetDirPath,
        gitUrl: gitUrl,
        ref: ref,
      );
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

  Future<void> _handleGit({
    required String targetDir,
    required String gitUrl,
    String? ref,
  }) async {
    final dir = Directory(targetDir);
    if (!dir.existsSync()) {
      await run('git clone $gitUrl $targetDir');
    }
    if (ref != null) {
      await run('git checkout $ref', workingDirectory: targetDir);
    }
  }
}
