import 'package:args/command_runner.dart';
import 'package:compile/compile.dart';
import 'package:path/path.dart';

abstract class BaseCommand<T> extends Command<T> with LogMixin {
  BaseCommand() {
    init(argParser);
  }

  bool get showAlias => true;

  final command = 'mobipkg';

  @override
  String get description {
    if (showAlias && aliases.isNotEmpty) {
      return '$commandDescription  ( Alias for: ${aliases.join(', ')} )';
    }
    return commandDescription;
  }

  @override
  String? get usageFooter {
    if (showAlias && aliases.isNotEmpty) {
      return '\nAlias for: ${aliases.join(', ')}';
    }
    return null;
  }

  void init(ArgParser argParser) {}

  String get commandDescription;

  @override
  FutureOr<T>? run() {
    try {
      return runCommand();
    } catch (exception, st) {
      return onError(exception, st);
    }
  }

  FutureOr<T>? runCommand();

  FutureOr<T>? onError(Object exception, StackTrace st);
}

abstract class BaseVoidCommand extends BaseCommand<void> {
  @override
  FutureOr<void>? onError(Object exception, StackTrace st) {
    print('Happen error when run command');
    print(exception);
    print(st);
    return null;
  }
}

abstract class BaseListCommand extends BaseVoidCommand {
  List<Command<void>> get subCommands;

  BaseListCommand() {
    subCommands.forEach(addSubcommand);
  }

  @override
  void runCommand() {}
}

mixin CompilerCommandMixin on BaseVoidCommand {
  LibType get libType;

  /// Check project
  FutureOr<void> checkProject(Lib lib) async {
    if (lib.type != libType) {
      throw Exception(
        'Project type not match'
        'project type is ${lib.type}, '
        'But compiler type is $libType',
      );
    }

    await doCheckProject(lib);
  }

  FutureOr<void> doCheckProject(Lib lib) {}

  void doCheckEnvAndCommand() {}

  @override
  Future<void> runCommand() async {
    doCheckEnvAndCommand();
    final projectDir = normalize(absolute(compileOptions.projectPath));

    print('Change working directory to $projectDir');
    Directory.current = projectDir;
    final lib = Lib.fromDir(Directory.current);
    await checkProject(lib);

    lib.analyze();

    // download
    if (compileOptions.removeOldSource) {
      await lib.removeOldSource();
      await lib.removeOldBuild();
    }
    await lib.download();

    await compile(lib);
  }

  FutureOr<void> compile(Lib lib) async {
    if (compileOptions.android) {
      await compileAndroid(lib);
    }
    if (compileOptions.ios && Platform.isMacOS) {
      await compileIOS(lib);
    }
  }

  FutureOr<void> compileAndroid(Lib lib) async {
    for (final type in AndroidCpuType.values) {
      final androidUtils = AndroidUtils(targetCpuType: type);
      final env = androidUtils.getEnvMap();
      final installRoot = lib.installPath;
      final prefix = join(installRoot, 'android', type.installName());

      _printEnv(env);
      await doCompileAndroid(lib, env, prefix, type);
    }
  }

  FutureOr<void> compileIOS(Lib lib) async {
    for (final type in IOSCpuType.values) {
      final iosUtils = IOSUtils(cpuType: type);
      final env = iosUtils.getEnvMap();
      final installRoot = lib.installPath;
      final prefix = join(installRoot, 'ios', type.installPath());

      _printEnv(env);
      await doCompileIOS(lib, env, prefix, type);
    }
  }

  void _printEnv(Map<String, String> env) {
    if (compileOptions.verbose) {
      i('Env:\n${env.debugString()}');
    }
  }

  FutureOr<void> doCompileAndroid(
      Lib lib, Map<String, String> env, String prefix, AndroidCpuType type);

  FutureOr<void> doCompileIOS(
      Lib lib, Map<String, String> env, String prefix, IOSCpuType type);
}
