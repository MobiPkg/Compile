import 'package:compile/compile.dart';

BrewPkg getBrewPkg(String pkgName) {
  final cmd = 'brew info --json=v1 $pkgName';

  final result = shell.runSync(cmd);

  return BrewPkg(result.toJSONList().first as Map);
}

class BrewPkg {
  final Map map;

  BrewPkg(this.map);

  String get name => map.stringValue('name');

  String get desc => map.stringValue('desc');

  String get homepage => map.stringValue('homepage');

  String get version => map.getMap('versions').stringValue('stable');

  bool get isGithub {
    return Uri.parse(homepage).host == 'github.com';
  }

  String get url {
    if (isGithub) {
      if (homepage.endsWith('.git')) {
        return homepage;
      } else {
        return '$homepage.git';
      }
    } else {
      return map.getMap('urls').getMap('stable').stringValue('url');
    }
  }

  String? get buildType {
    final list = map['build_dependencies'] as List;
    if (list.contains('cmake')) {
      return 'cmake';
    } else if (list.contains('meson')) {
      return 'meson';
    } else if (list.contains('autotools')) {
      return 'autotools';
    } else {
      return null;
    }
  }
}
