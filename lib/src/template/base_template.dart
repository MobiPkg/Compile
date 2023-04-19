import 'package:compile/compile.dart';
import 'package:path/path.dart';
import 'package:yaml_edit/yaml_edit.dart';

class Template {
  String makeLib({
    required LibType? type,
    required LibSourceType sourceType,
    required String name,
  }) {
    final map = <String, dynamic>{};

    map['name'] = name;
    map['type'] = type?.value;
    final source = <String, dynamic>{};

    switch (sourceType) {
      case LibSourceType.git:
        source['git'] = {
          'url': 'https://github.com/libffi/libffi.git',
          'ref': 'v3.4.4'
        };
        break;
      case LibSourceType.path:
        source['path'] = 'example/libffi';
        break;
      case LibSourceType.http:
        source['http'] = {
          'url':
              'https://github.com/madler/zlib/archive/refs/tags/v1.2.13.tar.gz',
          'type': 'tar.gz',
        };
        break;
    }

    source['subpath'] = '.';

    map['source'] = source;
    map['license'] = 'license';

    map['flags'] = {
      'c': '-fPIC -O2 -Wall',
      'cxx': '-fPIC -O2 -Wall',
      'cpp': '',
      'ld': '',
    };

    if (type == LibType.cAutotools) {
      map['precompile'] = <String>['./autogen.sh'];
    }

    map['options'] = type?.defaultOptions;

    for (final key in map.keys.toList()) {
      if (map[key] == null) {
        map.remove(key);
      }
    }

    final yamlEditor = YamlEditor('');
    yamlEditor.update([], map);

    return yamlEditor.toString();
  }

  String makeGitIgnore() {
    final buffer = StringBuffer();
    buffer.writeln('build/');
    buffer.writeln('source/');
    buffer.writeln('install/');
    return buffer.toString();
  }

  void writeToDir({
    required String targetPath,
    required LibType? type,
    required LibSourceType sourceType,
  }) {
    final dir = Directory(targetPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final name = basename(targetPath);
    final libFile = join(targetPath, 'lib.yaml').file();
    libFile.writeAsStringSync(
      makeLib(type: type, sourceType: sourceType, name: name),
    );

    final ignoreFile = join(targetPath, '.gitignore').file();
    ignoreFile.writeAsStringSync(makeGitIgnore());
  }
}
