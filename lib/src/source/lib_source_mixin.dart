import 'package:compile/compile.dart';

mixin LibSourceMixin {
  Map get map;

  Map get sourceMap => map['source'];

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
    return GitSource.fromMap(sourceMap['git']);
  }

  PathSource get pathSource {
    return PathSource(sourceMap['path']);
  }

  HttpSource get httpSource {
    return HttpSource.fromMap(sourceMap['http']);
  }
}

class GitSource {
  final String url;
  final String? ref;
  GitSource(this.url, this.ref);

  factory GitSource.fromMap(Map map) {
    final url = map['url'];
    final ref = map['ref'];
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
    final url = map['url'];
    final type = map['type'];
    return HttpSource(url, type);
  }

  LibHttpSourceType get typeEnum {
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
