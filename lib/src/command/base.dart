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

  late int cpuCount = envs.cpuCount;
}

abstract class BaseVoidCommand extends BaseCommand<void> {
  @override
  FutureOr<void>? onError(Object exception, StackTrace st) {
    simpleLogger.i('Happen error when run command');
    simpleLogger.i(exception);
    simpleLogger.i(st);
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
        'Project type not match, '
        'current project type is ${lib.type}, '
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

    logger.info('Change working directory to $projectDir');
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

    // pre compile
    await precompile(lib);

    await compile(lib);

    logger.info('Compile done');
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

      if (compileOptions.strip) {
        await androidUtils.stripDynamicLib(prefix);
      }

      _copyLicense(lib, prefix);
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

      if (compileOptions.strip) {
        await iosUtils.stripDynamicLib(prefix);
      }

      _copyLicense(lib, prefix);
    }
  }

  void _copyLicense(Lib lib, String installPath) {
    final licensePath = lib.licensePath;

    if (licensePath != null) {
      final srcLicenseFile = File(licensePath);
      if (srcLicenseFile.existsSync()) {
        final dstLicenseFile = File(join(installPath, 'LICENSE'));
        dstLicenseFile.createSync(recursive: true);
        dstLicenseFile.writeAsStringSync(
          srcLicenseFile.readAsStringSync(),
        );
        logger.info('Copy $licensePath file to $installPath');
      } else {
        logger.w('The license file is not exist: $licensePath');
      }
    }
  }

  void _printEnv(Map<String, String> env) {
    if (compileOptions.verbose) {
      i('Env:\n${env.debugString()}');
    }
  }

  FutureOr<void> doCompileAndroid(
    Lib lib,
    Map<String, String> env,
    String prefix,
    AndroidCpuType type,
  );

  FutureOr<void> doCompileIOS(
    Lib lib,
    Map<String, String> env,
    String prefix,
    IOSCpuType type,
  );

  FutureOr<void> precompile(Lib lib) async {
    final preCompile = lib.precompile;
    if (preCompile.isNotEmpty) {
      for (final script in preCompile) {
        await shell.run(script, workingDirectory: lib.workingPath);
      }
    } else {
      logger.i('No precompile script');
    }

    await doPrecompile(lib);
  }

  FutureOr<void> doPrecompile(Lib lib) async {}
}
