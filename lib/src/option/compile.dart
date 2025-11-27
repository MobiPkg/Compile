import 'package:compile/compile.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

final compileOptions = CompileOptions();

class CompileOptions {
  /// Android 默认开启
  bool android = true;

  List<AndroidCpuType> androidCpuTypes = AndroidCpuType.values;

  /// iOS 仅在 macOS 上默认开启
  bool ios = Platform.isMacOS;

  /// 默认编译 arm64 和 arm64-simulator，不包含 x86_64
  List<IOSCpuType> iosCpuTypes = const [IOSCpuType.arm64, IOSCpuType.arm64Simulator];

  /// 鸿蒙默认不开启，需要显式开启
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

  String? _logDir;

  String? get logDir => _logDir;

  set logDir(String? value) {
    if (value != null) {
      final dir = Directory(value).absolute.path;
      _logDir = normalize(dir);
    } else {
      _logDir = value;
    }
  }
}

extension CompileOptionsExt on CompileOptions {
  void initArgParser(ArgParser argParser) {
    argParser.addFlag(
      'android',
      abbr: 'a',
      defaultsTo: true,
      help: 'Whether compile android library.',
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
      defaultsTo: Platform.isMacOS,
      help: 'Whether compile ios library (default: true on macOS only).',
    );
    argParser.addMultiOption(
      'ios-cpu',
      help: 'Set ios cpu, support: ${IOSCpuType.args().join(", ")}, all. '
          'Default: arm64, arm64-simulator. Use "all" to include x86_64.',
      allowed: [...IOSCpuType.args(), 'all'],
    );
    argParser.addFlag(
      'harmony',
      abbr: 'H',
      help: 'Whether compile harmony library.',
    );
    argParser.addMultiOption(
      'harmony-cpu',
      help: 'Set harmony cpu, support: arm64, armv7, armv7s, x86_64, i386.',
      allowed: HarmonyCpuType.args(),
      defaultsTo: HarmonyCpuType.args(),
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
    argParser.addOption(
      'log-dir',
      abbr: 'L',
      help: 'Set compile log directory. '
          'If not specified, logs will be saved to <lib>/build/logs/',
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
      final iosCpuList = (result['ios-cpu'] as List).whereType<String>().toList();
      // 如果用户没有指定 ios-cpu，使用默认架构 (arm64, arm64-simulator)
      // 如果指定 'all'，使用所有架构
      if (iosCpuList.isEmpty) {
        iosCpuTypes = const [IOSCpuType.arm64, IOSCpuType.arm64Simulator];
      } else if (iosCpuList.contains('all')) {
        iosCpuTypes = IOSCpuType.values;
      } else {
        iosCpuTypes = iosCpuList.map((e) => IOSCpuType.from(e)).toList();
      }
      harmony = result['harmony'] as bool;
      harmonyCpuTypes = (result['harmony-cpu'] as List)
          .whereType<String>()
          .map((e) => HarmonyCpuType.from(e))
          .toList();
      removeOldSource = result['remove-old-source'] as bool;
      strip = result['strip'] as bool;
      gitDepth = int.parse(result['git-depth'] as String);
      installPrefix = result['install-prefix'] as String?;
      dependencyPrefix = result['dependency-prefix'] as String?;
      logDir = result['log-dir'] as String?;
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
