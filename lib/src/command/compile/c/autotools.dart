import 'package:compile/compile.dart';
import 'package:path/path.dart';

class AutoToolsCommand extends BaseVoidCommand with CompilerCommandMixin {
  @override
  String get commandDescription => 'AutoTools compile';

  @override
  String get name => 'autotools';

  @override
  List<String> get aliases => ['at', 'a'];

  @override
  LibType get libType => LibType.cAutotools;

  @override
  void doCheckEnvAndCommand() {
    super.doCheckEnvAndCommand();
    checkWhich('autoreconf');
    checkWhich('make');
  }

  @override
  Future<FutureOr<void>> doCompileAndroid(
    Lib lib,
    Map<String, String> env,
    String prefix,
    AndroidCpuType type,
  ) async {
    await _compile(lib, env, prefix, type);
  }

  @override
  FutureOr<void> doCompileIOS(
    Lib lib,
    Map<String, String> env,
    String prefix,
    IOSCpuType type,
  ) async {
    await _compile(lib, env, prefix, type);
  }

  @override
  FutureOr<void> doPrecompile(Lib lib) async {
    await super.doPrecompile(lib);
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
      cpuType.installPath(),
      'lib',
    );

    env['LIBRARY_PATH'] = libPath;
  }

  Future<void> _compile(
    Lib lib,
    Map<String, String> env,
    String prefix,
    CpuType cpuType,
  ) async {
    lib.injectEnv(env);
    lib.injectPrefix(env, cpuType);
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
    if (compileOptions.justMakeShell) {
      final shellBuffer = StringBuffer();
      shellBuffer.writeln(env.toEnvString(export: true, separator: '\n'));
      shellBuffer.writeln('cd $sourceDir');
      shellBuffer.writeln('./configure --prefix=$prefix --host $host $opt');
      shellBuffer.writeln('cd $sourceDir');
      shellBuffer.writeln('make -j$cpuNumber');
      shellBuffer.writeln('make install');
      makeCompileShell(lib, shellBuffer.toString(), cpuType);
      logger.info('Just make shell, skip compile.');
      return;
    }

    final cmd = './configure --prefix=$prefix --host $host $opt';
    await shell.run(
      cmd,
      workingDirectory: sourceDir,
      environment: env,
    );

    // make

    await shell.run(
      'make -j$cpuNumber',
      workingDirectory: sourceDir,
      environment: env,
    );

    // make install
    await shell.run(
      'make install',
      workingDirectory: sourceDir,
      environment: env,
    );
  }

  @override
  bool get buildMultiiOSArch => false;
}
