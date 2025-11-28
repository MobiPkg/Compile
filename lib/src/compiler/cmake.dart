import 'package:compile/compile.dart';
import 'package:path/path.dart';

class CMakeCompiler extends BaseCompiler {
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
    final ndk = envs.androidNDK;
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
  FutureOr<void> doCompileHarmony(
    Lib lib,
    Map<String, String> env,
    String depPrefix,
    String installPrefix,
    HarmonyCpuType type,
  ) async {
    final ndk = envs.harmonyNdk;
    final toolchainPath = join(
      ndk,
      'build',
      'cmake',
      'ohos.toolchain.cmake',
    );
    await _compile(
      lib,
      env,
      depPrefix,
      installPrefix,
      toolchainPath,
      {
        'OHOS_ARCH': type.cpuName(),
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

    final iosUtils = IOSUtils(cpuType: type);

    await _compile(
      lib,
      {
        ...env,
        'SDKROOT': iosUtils.sysroot(),
      },
      depPrefix,
      installPrefix,
      toolchainPath,
      {
        'CMAKE_SYSTEM_NAME': 'iOS',
        'CMAKE_OSX_ARCHITECTURES': arch,
        'CMAKE_SYSTEM_PROCESSOR': arch,
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
    String toolchainPath,
    Map<String, String> params,
    CpuType cpuType,
  ) async {
    injectFlagsToEnv(lib, env, cpuType);
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

    paramMap['CMAKE_C_FLAGS_RELEASE'] = cpuType.cFlags(lib).toFlagString();
    paramMap['CMAKE_CXX_FLAGS_RELEASE'] = cpuType.cxxFlags(lib).toFlagString();
    paramMap['CMAKE_EXE_LINKER_FLAGS_RELEASE'] =
        cpuType.ldFlags(lib).toFlagString();

    // add LIBRARY_PATH to env for link library

    final argsBuffer = StringBuffer();

    for (final e in paramMap.entries) {
      argsBuffer.write(' -D${e.key}="${e.value}"');
    }

    // 获取平台特定的 options
    final platformName = cpuType.platformName();
    final platformOptions = lib.getOptionsForPlatform(platformName);
    for (final opt in platformOptions) {
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

    final configureCmd = 'cmake $args -S $sourceDir -B $buildPath -G Ninja';
    final buildCmd = 'ninja -j$cpuCount';
    const installCmd = 'ninja install';
    
    final cmakeErrorLog = join(buildPath, 'CMakeFiles', 'CMakeError.log');
    
    // CMake configure
    compileLogger.phase('CMake Configure');
    compileLogger.command(
      command: configureCmd,
      workingDirectory: sourceDir,
      environment: env,
    );
    
    try {
      await shell.run(configureCmd, environment: env, workingDirectory: sourceDir);
    } catch (e) {
      compileLogger.error(
        message: 'CMake configure failed',
        command: configureCmd,
        workingDirectory: sourceDir,
        environment: env,
        buildSystem: 'cmake',
        logFilePath: cmakeErrorLog,
      );
      rethrow;
    }
    
    // Ninja build
    compileLogger.phase('Ninja Build');
    compileLogger.command(
      command: buildCmd,
      workingDirectory: buildPath,
      environment: env,
    );
    
    try {
      await shell.run(
        buildCmd,
        environment: env,
        workingDirectory: buildPath,
      );
    } catch (e) {
      compileLogger.error(
        message: 'Ninja build failed',
        command: buildCmd,
        workingDirectory: buildPath,
        environment: env,
        buildSystem: 'cmake',
      );
      rethrow;
    }
    
    // Ninja install
    compileLogger.phase('Ninja Install');
    compileLogger.command(
      command: installCmd,
      workingDirectory: buildPath,
      environment: env,
    );
    
    try {
      await shell.run(
        installCmd,
        environment: env,
        workingDirectory: buildPath,
      );
    } catch (e) {
      compileLogger.error(
        message: 'Ninja install failed',
        command: installCmd,
        workingDirectory: buildPath,
        environment: env,
        buildSystem: 'cmake',
      );
      rethrow;
    }
    
    compileLogger.info('CMake compilation completed successfully');
    
    // 生成 lib.yaml 中配置的 pkg-config 文件
    if (lib.hasPkgConfig) {
      final installPrefix = cpuType.installPrefix(lib);
      await lib.generatePkgConfigFiles(installPrefix);
      for (final item in lib.pkgConfigItems) {
        compileLogger.info('Generated ${item.name}.pc');
      }
    }
  }

  @override
  FutureOr<void> doPrecompile(Lib lib) {}
}
