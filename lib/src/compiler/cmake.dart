import 'package:compile/compile.dart';
import 'package:path/path.dart';

class CMakeCompiler extends BaseCompiler {
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
      depPrefix,
      installPrefix,
      toolchainPath,
      {
        'ANDROID_NATIVE_API_LEVEL': '21',
        'ANDROID_ABI': type.cpuName(),
      },
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
    final toolchainPath = await createiOSToolchainFile(lib, type);

    final depPrefix = type.depPrefix();
    final installPrefix = type.installPrefix(lib);

    final arch = type.cmakeCpuName();
    final archParams = '$arch;$arch';

    await _compile(
      lib,
      {},
      depPrefix,
      installPrefix,
      toolchainPath,
      {
        'CMAKE_SYSTEM_NAME': 'iOS',
        'CMAKE_OSX_ARCHITECTURES': archParams,
      },
      type,
    );
  }

  @override
  FutureOr<void> compileMultiCpuIos(Lib lib) async {
    final cpuType = IOSCpuType.universal;

    final toolchainPath = await createiOSToolchainFile(lib, cpuType);

    final depPrefix = cpuType.depPrefix();
    final installPrefix = cpuType.installPrefix(lib);

    await _compile(
      lib,
      {},
      depPrefix,
      installPrefix,
      toolchainPath,
      {
        'CMAKE_SYSTEM_NAME': 'iOS',
        'CMAKE_OSX_ARCHITECTURES': IOSCpuType.universal.cmakeCpuName(),
      },
      cpuType,
    );
  }

  Future<String> createiOSToolchainFile(
    Lib lib,
    CpuType type,
  ) async {
    final toolchainFile = join(
      lib.toolchainPath,
      type.cpuName(),
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

  void _setLibrarayPath(
    Map<String, String> env,
    Map<String, String> params,
    CpuType cpuType,
  ) {
    final depPrefix = cpuType.depPrefix();
    if (depPrefix.isEmpty) {
      return;
    }
    final libPath = join(depPrefix, 'lib');
    env['LIBRARY_PATH'] = libPath; // For find library when compile.
    params['CMAKE_INSTALL_RPATH'] = libPath; // For find library when run.
  }

  Future<void> _compile(
    Lib lib,
    Map<String, String> env,
    String depPrefix,
    String installPrefix,
    String toolchainPath,
    Map<String, String> params,
    CpuType cpuType,
  ) async {
    lib.injectEnv(env);
    lib.injectPrefix(env, depPrefix, cpuType);

    _setLibrarayPath(env, params, cpuType);

    final sourceDir = lib.workingPath;
    final buildDir = join(lib.buildPath, cpuType.platform).directory();

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
    log.writeln('depPrefix: $depPrefix');
    log.writeln('installPrefix: $installPrefix');

    logger.i(log.toString().trim());

    final paramMap = {
      ...params,
      'CMAKE_TOOLCHAIN_FILE': toolchainPath,
      'CMAKE_INSTALL_PREFIX': installPrefix,
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
    if (compileOptions.justMakeShell) {
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
    if (compileOptions.justMakeShell) {
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
  FutureOr<void> doPrecompile(Lib lib) {}
}
