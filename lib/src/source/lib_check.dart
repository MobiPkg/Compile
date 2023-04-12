import 'package:compile/compile.dart';

enum LibSourceType with ConfigType {
  git,
  path,
  http;

  const LibSourceType();

  @override
  String get value => toString().split('.').last;

  static LibSourceType fromValue(String value) {
    for (final type in values) {
      if (type.value == value) {
        return type;
      }
    }
    throw Exception('Not support type: $value');
  }
}

enum LibHttpSourceType {
  zip,
  tar,
  tarGz,
  tarBz2,
  tarXz,
  xz,
  lzma,
  tarLzma,
  sevenZ;

  void checkCommand() {
    switch (this) {
      case LibHttpSourceType.zip:
        checkWhich('unzip');
        break;
      case LibHttpSourceType.tar:
        checkWhich('tar');
        break;
      case LibHttpSourceType.tarGz:
        checkWhich('tar');
        checkWhich('gzip');
        break;
      case LibHttpSourceType.tarBz2:
        checkWhich('tar');
        checkWhich('bzip2');
        break;
      case LibHttpSourceType.tarXz:
        checkWhich('tar');
        checkWhich('xz');
        break;
      case LibHttpSourceType.sevenZ:
        checkWhich('7z');
        break;
      case LibHttpSourceType.xz:
        checkWhich('xz');
        break;
      case LibHttpSourceType.lzma:
        checkWhich('lzma');
        break;
      case LibHttpSourceType.tarLzma:
        checkWhich('tar');
        checkWhich('lzma');
        break;
    }
  }
}

mixin LibCheckMixin on LibSourceMixin {
  void _throwError(String message) {
    throw Exception(message);
  }

  void analyze() {
    final source = map.getMapOrNull('source');
    if (source == null) {
      throw Exception('Not found source in lib.yaml');
    }
    if (source['git'] != null) {
      final git = source.getMapOrNull('git');
      if (git == null) {
        _throwError('git is must be map.');
      }
      _checkGit(git!);
    } else if (source['path'] != null) {
      final path = source['path'];
      _checkPath(path);
    } else if (source['http'] != null) {
      final http = source['http'];

      if (http is! Map) {
        _throwError('http is must be map.');
      }
      _checkHttp(http as Map);
    } else {
      throw Exception('Not support source type');
    }
  }

  void _checkGit(Map git) {
    final url = git['url'];
    final ref = git['ref'];

    checkWhich('git');

    if (url == null || url is! String) {
      _throwError('url is must be string.');
    }
    if (ref != null && ref is! String) {
      _throwError('ref is must be string.');
    }
  }

  void _checkPath(dynamic path) {
    checkWhich('cp');
    if (path is! String) {
      _throwError('path is must be string.');
    }
    if (!FileSystemEntity.isDirectorySync(path as String)) {
      _throwError('path is must be directory.');
    }
  }

  void _checkHttp(Map http) {
    checkWhich('wget');

    final url = http.stringValueOrNull('url');
    final type = http['type'];

    if (url == null) {
      _throwError('url is must be string.');
    }

    final uri = Uri.parse(url!);
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      _throwError('http is must be http or https.');
    }

    if (type != null && type is! String) {
      _throwError('type is must be string.');
    }

    httpSourceType.checkCommand();
  }

  LibHttpSourceType get httpSourceType {
    final type = map.getMap('http').stringValue('type');
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
