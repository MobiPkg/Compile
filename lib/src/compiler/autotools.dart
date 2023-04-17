import 'package:compile/compile.dart';
import 'package:path/path.dart';

class AutoToolsCompiler extends BaseCompiler {
  @override
  bool get buildMultiiOSArch => false;

  @override
  void doCheckEnvAndCommand() {
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
  FutureOr<void> doPrecompile(Lib lib) async {
    final sourceDir = lib.workingPath;

    // check configure exists
    if (!File(join(sourceDir, 'configure')).existsSync()) {
      simpleLogger.i('configure not found');
      await shell.run('autoreconf -i -v', workingDirectory: sourceDir);
    }

    // check configure exists
    if (!File(join(sourceDir, 'configure')).existsSync()) {
      simpleLogger.i('configure not found');
      return;
    }
  }

  void _setLibrarayPath(
    Map<String, String> env,
    CpuType cpuType,
  ) {
    final prefix = envs.prefix;
    if (prefix == null) {
      return;
    }

    final libPath = join(
      prefix,
      cpuType.platformName(),
      cpuType.cpuName(),
      'lib',
    );

    env['LIBRARY_PATH'] = libPath;
  }

  Future<void> _compile(
    Lib lib,
    Map<String, String> env,
    String depPrefix,
    String installPrefix,
    CpuType cpuType,
  ) async {
    lib.injectEnv(env);
    lib.injectPrefix(env, depPrefix, cpuType);
    _setLibrarayPath(env, cpuType);

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
    final opt = lib.options.joinWithSpace();

    final configureCmd =
        './configure --prefix=$depPrefix --exec-prefix $installPrefix --host $host $opt';
    final makeCmd = 'make -j$cpuNumber';
    const makeInstallCmd = 'make install';

    if (compileOptions.justMakeShell) {
      final shellBuffer = StringBuffer();
      shellBuffer.writeln(env.toEnvString(export: true, separator: '\n'));
      shellBuffer.writeln('cd $sourceDir');
      shellBuffer.writeln(configureCmd.formatCommandDefault());
      shellBuffer.writeln('cd $sourceDir');
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

    // make

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
}
