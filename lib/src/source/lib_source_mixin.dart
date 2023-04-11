import 'package:compile/compile.dart';

mixin LibSourceMixin {
  Map get map;

  Map get sourceMap => map['source'] as Map;

  LibSourceType get sourceType {
    if (sourceMap.containsKey('git')) {
      return LibSourceType.git;
    } else if (sourceMap.containsKey('path')) {
      return LibSourceType.path;
    } else if (sourceMap.containsKey('http')) {
      return LibSourceType.http;
    }
    throw Exception('Not support source type');
  }

  GitSource get gitSource {
    return GitSource.fromMap(sourceMap['git'] as Map);
  }

  PathSource get pathSource {
    return PathSource(sourceMap['path'] as String);
  }

  HttpSource get httpSource {
    return HttpSource.fromMap(sourceMap['http'] as Map);
  }
}

class GitSource {
  final String url;
  final String? ref;
  GitSource(this.url, this.ref);

  factory GitSource.fromMap(Map map) {
    final url = map['url'] as String;
    final ref = map['ref'] as String;
    return GitSource(url, ref);
  }
}

class PathSource {
  final String path;
  PathSource(this.path);
}

class HttpSource {
  final String url;
  final String type;

  HttpSource(this.url, this.type);

  factory HttpSource.fromMap(Map map) {
    final url = map['url'] as String;
    final type = map['type'] as String;
    return HttpSource(url, type);
  }

  LibHttpSourceType get typeEnum {
    if (type == 'zip') {
      return LibHttpSourceType.zip;
    } else if (type == 'tar') {
      return LibHttpSourceType.tar;
    } else if (type == 'tar.gz' || type == 'tgz') {
      return LibHttpSourceType.tarGz;
    } else if (type == 'tar.bz2' || type == 'tbz2' || type == 'bzip2') {
      return LibHttpSourceType.tarBz2;
    } else if (type == 'tar.xz' || type == 'txz') {
      return LibHttpSourceType.tarXz;
    } else if (type == '7z') {
      return LibHttpSourceType.sevenZ;
    }
    throw Exception('Not support http source type: $type');
  }
}
