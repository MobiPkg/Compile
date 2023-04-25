import 'package:compile/compile.dart';
import 'package:path/path.dart';

class AutoToolsCompiler extends BaseCompiler {
  @override
  bool get buildMultiiOSArch => false;

  @override
  void doCheckEnvAndCommand(Lib lib) {
    checkWhich('autoreconf');
    checkWhich('make');
  }

  @override
  FutureOr<void> doCompileAndroid(
    Lib lib,
    Map<String, String> env,
    String depPrefix,
    String installPrefix,
    AndroidCpuType type,
  ) async {
    await _compile(
      lib,
      env,
      depPrefix,
      installPrefix,
      type,
    );
  }

  @override
  FutureOr<void> doCompileIOS(
    Lib lib,
    Map<String, String> env,
    String depPrefix,
    String installPrefix,
    IOSCpuType type,
  ) async {
    await _compile(
      lib,
      env,
      depPrefix,
      installPrefix,
      type,
    );
  }

  @override
  FutureOr<void> doCompileHarmony(
    Lib lib,
    Map<String, String> env,
    String depPrefix,
    String installPrefix,
    HarmonyCpuType type,
  ) async {
    await _compile(
      lib,
      env,
      depPrefix,
      installPrefix,
      type,
    );
  }

  @override
  FutureOr<void> doPrecompile(Lib lib) async {
    final sourceDir = lib.workingPath;

    // check configure exists
    if (!File(join(sourceDir, 'configure')).existsSync()) {
      simpleLogger.i('configure not found');

      // check autogen.sh exists
      if (File(join(sourceDir, 'autogen.sh')).existsSync()) {
        simpleLogger.i('autogen.sh found, run it.');
        await shell.run('./autogen.sh', workingDirectory: sourceDir);
      } else {
        simpleLogger.i('autogen.sh not found, try run `autoreconf -i -v`.');
        await shell.run('autoreconf -i -v', workingDirectory: sourceDir);
      }
    }

    // check configure exists
    if (!File(join(sourceDir, 'configure')).existsSync()) {
      simpleLogger.i('configure not found');
      return;
    }
  }

  void injectFlagsToEnv(
    Lib lib,
    Map<String, String> env,
    CpuType cpuType,
  ) {
    env['CFLAGS'] = cpuType.cFlags(lib).toFlagString();
    env['CPPFLAGS'] = cpuType.cppFlags(lib).toFlagString();
    env['CXXFLAGS'] = cpuType.cxxFlags(lib).toFlagString();
    env['LDFLAGS'] = cpuType.ldFlags(lib).toFlagString();
  }

  Future<void> _compile(
    Lib lib,
    Map<String, String> env,
    String depPrefix,
    String installPrefix,
    CpuType cpuType,
  ) async {
    final sourceDir = lib.workingPath;

    final host = env['HOST'];
    if (host == null) {
      simpleLogger.i('HOST not found');
      return;
    }

    final makeFile = File(join(sourceDir, 'Makefile'));
    if (makeFile.existsSync()) {
      try {
        await shell.run(
          'make clean',
          workingDirectory: sourceDir,
          environment: env,
        );
      } catch (e) {
        // ignore
      }
    }
    // cpu number
    final cpuNumber = envs.cpuCount;
    final opt = lib.options.toFlagString();

    if (depPrefix.isEmpty) {
      // ignore: parameter_assignments
      depPrefix = installPrefix;
    }

    final configureCmd =
        './configure --prefix=$depPrefix --exec-prefix $installPrefix --host $host $opt';
    const makeCleanCmd = 'make clean';
    final makeCmd = 'make -j$cpuNumber';
    const makeInstallCmd = 'make install';

    if (compileOptions.justMakeShell) {
      final shellBuffer = StringBuffer();
      shellBuffer.writeln(env.toEnvString(export: true, separator: '\n'));
      shellBuffer.writeln('cd $sourceDir');
      shellBuffer.writeln(configureCmd.formatCommandDefault());
      shellBuffer.writeln('cd $sourceDir');
      shellBuffer.writeln(makeCleanCmd);
      shellBuffer.writeln(makeCmd);
      shellBuffer.writeln(makeInstallCmd);
      makeCompileShell(lib, shellBuffer.toString(), cpuType);
      logger.info('Just make shell, skip compile.');
      return;
    }

    await shell.run(
      configureCmd,
      workingDirectory: sourceDir,
      environment: env,
    );

    // make clean (ignore error)
    try {
      await shell.run(
        makeCleanCmd,
        workingDirectory: sourceDir,
        environment: env,
      );
    } catch (e) {
      // ignore
    }

    await shell.run(
      makeCmd,
      workingDirectory: sourceDir,
      environment: env,
    );

    // make install
    await shell.run(
      makeInstallCmd,
      workingDirectory: sourceDir,
      environment: env,
    );
  }

  @override
  Future<void> onCompileError(Lib lib, Object err, StackTrace st) async {
    final usageCommand = join(lib.workingPath, 'configure --help');
    await shell.run(usageCommand, workingDirectory: lib.workingPath);
  }
}
