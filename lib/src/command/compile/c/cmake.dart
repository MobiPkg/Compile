import 'package:compile/compile.dart';
import 'package:path/path.dart';

class CMakeCommand extends BaseVoidCommand with CompilerCommandMixin, LogMixin {
  @override
  String get commandDescription => 'CMake compile';

  @override
  LibType get libType => LibType.cCmake;

  @override
  String get name => 'cmake';

  @override
  List<String> get aliases => ['cm'];

  @override
  void doCheckEnvAndCommand() {
    super.doCheckEnvAndCommand();
    checkWhich('autoreconf');
    checkWhich('make');
  }

  @override
  FutureOr<void> doCompileAndroid(
    Lib lib,
    Map<String, String> env,
    String prefix,
    AndroidCpuType type,
  ) async {
    final ndk = env[Consts.ndkKey];
    if (ndk == null) {
      throw Exception('Not found ndk in env');
    }
    final toolchainPath = join(
      ndk,
      'build',
      'cmake',
      'android.toolchain.cmake',
    );
    await _compile(
      lib,
      env,
      prefix,
      toolchainPath,
      {
        'ANDROID_NATIVE_API_LEVEL': '21',
        'ANDROID_ABI': type.installPath(),
      },
      type,
    );
  }

  @override
  FutureOr<void> doCompileIOS(
    Lib lib,
    Map<String, String> env,
    String prefix,
    IOSCpuType type,
  ) async {
    // do not use
  }

  @override
  FutureOr<void> compileMultiCpuIos(Lib lib) async {
    final toolchainPath = await createiOSToolchainFile(lib);

    final prefix = join(lib.installPath, 'ios', Consts.iOSMutilArchName);

    await _compile(
      lib,
      {},
      prefix,
      toolchainPath,
      {
        'CMAKE_SYSTEM_NAME': 'iOS',
        'CMAKE_OSX_ARCHITECTURES': IOSCpuType.cmakeArchsString(),
      },
      CpuType.universal,
    );
  }

  Future<String> createiOSToolchainFile(
    Lib lib,
  ) async {
    final toolchainFile = join(
      lib.sourcePath,
      Consts.iOSMutilArchName,
      'ios.toolchain.cmake',
    ).file(createWhenNotExists: true);

    const toolchainContent = '''
# iOS Toolchain

# Set the target system name
set(CMAKE_SYSTEM_NAME iOS)
''';
    toolchainFile.writeAsStringSync(toolchainContent);

    logger.info('create toolchain file: ${toolchainFile.path}');
    logger.info('content: \n${toolchainFile.readAsStringSync()}');

    return toolchainFile.absolute.path;
  }

  Future<void> _compile(
    Lib lib,
    Map<String, String> env,
    String prefix,
    String toolchainPath,
    Map<String, String> params,
    CpuType cpuType,
  ) async {
    lib.injectEnv(env);
    lib.injectPrefix(env, cpuType);

    final sourceDir = lib.workingPath;
    final host = env['HOST'];
    final buildDir = join(lib.buildPath, host).directory();

    final log = StringBuffer();

    final buildPath = buildDir.absolute.path;
    log.writeln('sourceDir: $sourceDir');

    if (buildDir.existsSync()) {
      log.writeln('remove old buildDir: $buildPath');
      buildDir.deleteSync(recursive: true);
    }
    buildDir.createSync(recursive: true);
    log.writeln('buildPath: $buildPath');
    log.writeln('toolchainPath: $toolchainPath');
    log.writeln('prefix: $prefix');

    logger.i(log.toString().trim());

    final paramMap = {
      ...params,
      'CMAKE_TOOLCHAIN_FILE': toolchainPath,
      'CMAKE_INSTALL_PREFIX': prefix,
      'CMAKE_BUILD_TYPE': 'Release',
    };

    // add LIBRARY_PATH to env for link library

    lib.addFlagsToCmakeArgs(paramMap);

    final argsBuffer = StringBuffer();

    for (final e in paramMap.entries) {
      argsBuffer.write(' -D${e.key}="${e.value}"');
    }

    for (final opt in lib.options) {
      argsBuffer.write(' $opt');
    }

    final args = argsBuffer.toString().trim();

    if (checkWhich('ninja', throwOnError: false)) {
      await _compileWithNinja(lib, args, sourceDir, buildPath, env, cpuType);
    } else {
      await _compileWithMake(lib, args, sourceDir, buildPath, env, cpuType);
    }
  }

  Future<void> _compileWithMake(
    Lib lib,
    String args,
    String sourceDir,
    String buildPath,
    Map<String, String> env,
    CpuType cpuType,
  ) async {
    final cmdBuffer = StringBuffer();
    cmdBuffer.writeln(env.toEnvString(export: true, separator: '\n'));
    cmdBuffer.writeln('cd $sourceDir');
    cmdBuffer.writeln();
    cmdBuffer.writeln(
      'cmake $args -S $sourceDir -B $buildPath'.formatCommand([
        RegExp('-[DSBG]'),
      ]),
    );

    cmdBuffer.writeln('cd $buildPath');
    cmdBuffer.writeln('make -j$cpuCount');
    cmdBuffer.writeln('make install');
    makeCompileShell(lib, cmdBuffer.toString(), cpuType);

    if (compileOptions.justMakeShell) {
      logger.info('Just make shell, skip compile.');
      return;
    }

    final cmd = 'cmake $args -S $sourceDir -B $buildPath';
    // i('cmd: $cmd');
    await shell.run(cmd, environment: env, workingDirectory: sourceDir);
    await shell.run(
      'make -j$cpuCount',
      environment: env,
      workingDirectory: buildPath,
    );
    await shell.run(
      'make install',
      environment: env,
      workingDirectory: buildPath,
    );
  }

  Future<void> _compileWithNinja(
    Lib lib,
    String args,
    String sourceDir,
    String buildPath,
    Map<String, String> env,
    CpuType cpuType,
  ) async {
    final cmdBuffer = StringBuffer();
    cmdBuffer.writeln(env.toEnvString(export: true, separator: '\n'));
    cmdBuffer.writeln('cd $sourceDir');
    cmdBuffer.writeln();
    cmdBuffer.writeln(
      'cmake $args -S $sourceDir -B $buildPath -G Ninja'.formatCommand([
        RegExp('-[DSBG]'),
      ]),
    );

    cmdBuffer.writeln('cd $buildPath');
    cmdBuffer.writeln('ninja -j$cpuCount');
    cmdBuffer.writeln('ninja install');
    makeCompileShell(lib, cmdBuffer.toString(), cpuType);

    if (compileOptions.justMakeShell) {
      return;
    }

    final cmd = 'cmake $args -S $sourceDir -B $buildPath -G Ninja';
    await shell.run(cmd, environment: env, workingDirectory: sourceDir);
    await shell.run(
      'ninja -j$cpuCount',
      environment: env,
      workingDirectory: buildPath,
    );
    await shell.run(
      'ninja install',
      environment: env,
      workingDirectory: buildPath,
    );
  }

  @override
  bool get buildMultiiOSArch => true;
}
