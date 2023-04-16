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

extension CompileOptionsExt on CompileOptions {
  void initArgParser(ArgParser argParser) {
    argParser.addFlag(
      'android',
      abbr: 'a',
      defaultsTo: true,
      help: 'Print this usage information.',
    );
    argParser.addFlag(
      'ios',
      abbr: 'i',
      defaultsTo: true,
      help: 'Print this usage information.',
    );
    argParser.addOption(
      'project-path',
      abbr: 'C',
      defaultsTo: '.',
      help: 'Set project path.',
    );
    argParser.addFlag(
      'remove-old-source',
      abbr: 'R',
      help: 'Remove old build files before compile.',
    );
    argParser.addFlag(
      'strip',
      abbr: 's',
      defaultsTo: true,
      help: 'Strip symbols for dynamic libraries.',
    );
    argParser.addOption(
      'git-depth',
      abbr: 'g',
      help: 'If use git to download source, set git depth to 1.',
      defaultsTo: "1",
    );

    argParser.addFlag(
      'just-make-shell',
      abbr: 'j',
      help: 'Just make shell script, not run it. The command is help.',
      hide: true,
    );
    argParser.addOption(
      'install-prefix',
      abbr: 'I',
      help: 'Set install path.',
    );
    argParser.addOption(
      'dependency-prefix',
      abbr: 'p',
      help: 'Set dependencies prefix.',
    );
  }

  void configArgResults(ArgResults? result) {
    if (result != null) {
      android = result['android'] as bool;
      ios = result['ios'] as bool;
      projectPath = result['project-path'] as String;
      removeOldSource = result['remove-old-source'] as bool;
      strip = result['strip'] as bool;
      gitDepth = int.parse(result['git-depth'] as String);
      justMakeShell = result['just-make-shell'] as bool;
      installPrefix = result['install-prefix'] as String?;
      dependencyPrefix = result['dependency-prefix'] as String?;
    }
  }
}
