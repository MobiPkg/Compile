import 'package:compile/compile.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

final compileOptions = CompileOptions();

class CompileOptions {
  bool android = true;

  List<AndroidCpuType> androidCpuTypes = AndroidCpuType.values;

  bool ios = true;

  List<IOSCpuType> iosCpuTypes = IOSCpuType.values;

  bool harmony = false;

  List<HarmonyCpuType> harmonyCpuTypes = HarmonyCpuType.values;

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
    argParser.addMultiOption(
      'android-cpu',
      help: 'Set android cpu, support: arm64-v8a, armeabi-v7a, x86, x86_64.',
      allowed: AndroidCpuType.args(),
      defaultsTo: AndroidCpuType.args(),
    );
    argParser.addFlag(
      'ios',
      abbr: 'i',
      defaultsTo: true,
      help: 'Print this usage information.',
    );
    argParser.addMultiOption(
      'ios-cpu',
      help: 'Set ios cpu, support: arm64, armv7, armv7s, x86_64, i386.',
      allowed: IOSCpuType.args(),
      defaultsTo: IOSCpuType.args(),
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
      help: 'Just make shell script, not run it. '
          'The command is help developer to debug. '
          'So, it will be hidden in help message.',
      hide: true,
    );
    argParser.addOption(
      'install-prefix',
      abbr: 'I',
      help: 'Set install path. (Override envrionment variable: MOBIPKG_PREFIX.',
    );
    argParser.addOption(
      'dependency-prefix',
      abbr: 'p',
      help: 'Set dependencies prefix. '
          '(Override envrionment variable: MOBIPKG_PREFIX)',
    );
    argParser.addOption(
      'option-file',
      abbr: 'o',
      help: 'Set option file, if config option, '
          'other common options will be ignore.',
    );
  }

  void configArgResults(ArgResults? result) {
    if (result != null) {
      projectPath = result['project-path'] as String;
      justMakeShell = result['just-make-shell'] as bool;

      final optionPath = result['option-file'] as String?;
      if (optionPath != null) {
        _configOptionFile(optionPath);
        return;
      }

      android = result['android'] as bool;
      androidCpuTypes = (result['android-cpu'] as List)
          .whereType<String>()
          .map((e) => AndroidCpuType.from(e))
          .toList();
      ios = result['ios'] as bool;
      iosCpuTypes = (result['ios-cpu'] as List)
          .whereType<String>()
          .map((e) => IOSCpuType.from(e))
          .toList();
      removeOldSource = result['remove-old-source'] as bool;
      strip = result['strip'] as bool;
      gitDepth = int.parse(result['git-depth'] as String);
      installPrefix = result['install-prefix'] as String?;
      dependencyPrefix = result['dependency-prefix'] as String?;
    }
  }

  void _configOptionFile(String optionFile) {
    final file = File(optionFile);
    if (!file.existsSync()) {
      throw Exception('Option file not found: $optionFile');
    }
    final content = file.readAsStringSync();
    final map = loadYamlDocument(content).contents.value as Map;

    void configKeyWhenNotNull(
      String key,
      void Function(dynamic value) callback,
    ) {
      final value = map[key];
      if (value != null) {
        callback(value);
      }
    }

    String resolve(String path) {
      if (isAbsolute(path)) {
        return path;
      }
      final parent = file.parent.absolute;
      return normalize(join(parent.path, path));
    }

    configKeyWhenNotNull('android', (value) {
      android = value as bool;
    });
    configKeyWhenNotNull('ios', (value) {
      ios = value as bool;
    });
    configKeyWhenNotNull('remove-old-source', (value) {
      removeOldSource = value as bool;
    });
    configKeyWhenNotNull('strip', (value) {
      strip = value as bool;
    });
    configKeyWhenNotNull('git-depth', (value) {
      gitDepth = value as int;
    });
    configKeyWhenNotNull('just-make-shell', (value) {
      justMakeShell = value as bool;
    });
    configKeyWhenNotNull('install-prefix', (value) {
      installPrefix = resolve(value as String);
    });
    configKeyWhenNotNull('dependency-prefix', (value) {
      dependencyPrefix = resolve(value as String);
    });

    configKeyWhenNotNull('android-cpu', (value) {
      final list = value as List;
      androidCpuTypes =
          list.whereType<String>().map((e) => AndroidCpuType.from(e)).toList();
    });
    configKeyWhenNotNull('ios-cpu', (value) {
      final list = value as List;
      iosCpuTypes =
          list.whereType<String>().map((e) => IOSCpuType.from(e)).toList();
    });
  }
}
