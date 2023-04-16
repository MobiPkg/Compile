import 'package:compile/compile.dart';
import 'package:path/path.dart';

final compileOptions = CompileOptions();

class CompileOptions {
  bool android = true;

  bool ios = true;

  String projectPath = '.';

  bool removeOldSource = false;

  bool strip = false;

  int gitDepth = 1;

  bool justMakeShell = false;

  String? _installPrefix;

  String? get installPrefix => _installPrefix;

  set installPrefix(String? value) {
    if (value != null) {
      final dir = Directory(value).absolute.path;
      _installPrefix = normalize(dir);
    } else {
      _installPrefix = value;
    }
  }

  String? _dependencyPrefix;

  String? get dependencyPrefix => _dependencyPrefix;

  set dependencyPrefix(String? value) {
    if (value != null) {
      final dir = Directory(value).absolute.path;
      _dependencyPrefix = normalize(dir);
    } else {
      _dependencyPrefix = value;
    }
  }
}
