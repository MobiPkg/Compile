import 'dart:io';

import 'package:compile/compile.dart';

enum LibSourceType {
  git,
  path,
  http,
}

enum LibHttpSourceType {
  zip,
  tar,
  tarGz,
  tarBz2,
  sevenZ,
}

mixin LibCheckMixin on LibSourceMixin {
  

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
      if (git is! Map) {
        _throwError('git is must be map.');
      }
      _checkGit(git);
    } else if (source['path'] != null) {
      final path = source['path'];
      _checkPath(path);
    } else if (source['http'] != null) {
      final http = source['http'];
      _checkHttp(http);
    } else {
      throw Exception('Not support source type');
    }
  }

  void _checkGit(Map git) {
    final url = git['url'];
    final ref = git['ref'];

    if (url == null || url is! String) {
      _throwError('url is must be string.');
    }
    if (ref != null && ref is! String) {
      _throwError('ref is must be string.');
    }
  }

  void _checkPath(path) {
    if (path is! String) {
      _throwError('path is must be string.');
    }
    if (!FileSystemEntity.isDirectorySync(path)) {
      _throwError('path is must be directory.');
    }
  }

  void _checkHttp(Map http) {
    final url = http['url'];
    final type = http['type'];

    if (url == null || url is! String) {
      _throwError('url is must be string.');
    }

    final uri = Uri.parse(url);
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      _throwError('http is must be http or https.');
    }

    if (type != null && type is! String) {
      _throwError('type is must be string.');
    }
  }

  LibHttpSourceType get httpSourceType {
    final type = map['source']['type'];
    if (type == 'zip') {
      return LibHttpSourceType.zip;
    } else if (type == 'tar') {
      return LibHttpSourceType.tar;
    } else if (type == 'tar.gz' || type == 'tgz') {
      return LibHttpSourceType.tarGz;
    } else if (type == 'tar.bz2' || type == 'tbz2') {
      return LibHttpSourceType.tarBz2;
    } else if (type == '7z') {
      return LibHttpSourceType.sevenZ;
    }
    throw Exception('Not support http source type: $type');
  }
}
