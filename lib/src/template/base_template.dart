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
    BrewPkg? pkg;
    try {
      pkg = getBrewPkg(name);
    } catch (e) {
      logger.debug(e);
    }

    map['name'] = pkg?.name ?? name;
    map['type'] = pkg?.buildType ?? type?.value;

    final source = <String, dynamic>{};
    if (pkg != null) {
      if (pkg.isGithub) {
        sourceType = LibSourceType.git;
      } else {
        // ignore: parameter_assignments
        sourceType = LibSourceType.http;
      }

      map['homepage'] = pkg.homepage;
      map['description'] = pkg.desc;
      map['license-type'] = pkg.licenseType;
    }

    source['subpath'] = '.';
    switch (sourceType) {
      case LibSourceType.git:
        source['git'] = {
          'url': pkg?.url ?? 'https://github.com/libffi/libffi.git',
          'ref': pkg?.version ?? 'v1.0.0',
        };
        break;
      case LibSourceType.path:
        source['path'] = 'example/libffi';
        break;
      case LibSourceType.http:
        {
          final url = pkg?.url ??
              'https://github.com/libffi/libffi/archive/refs/tags/v1.0.0.tar.gz';
          source['http'] = {
            'url': url,
            'type': 'tar.gz',
            'version': pkg?.version ?? 'v1.0.0',
          };
          break;
        }
    }

    map['source'] = source;
    map['license'] = 'LICENSE';

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
