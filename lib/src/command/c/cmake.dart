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
    final toolchainPath =
        join(ndk, 'build', 'cmake', 'android.toolchain.cmake');
    await _compile(lib, env, prefix, toolchainPath, {
      'ANDROID_NATIVE_API_LEVEL': '21',
      'ANDROID_ABI': type.installName(),
    });
  }

  @override
  FutureOr<void> doCompileIOS(
    Lib lib,
    Map<String, String> env,
    String prefix,
    IOSCpuType type,
  ) async {
    final toolchain = await createiOSToolchainFile(lib, type, env);
    final sdkPath = await IOSUtils(cpuType: type).getSdkPath();
    await _compile(lib, env, prefix, toolchain, {
      'CMAKE_OSX_SYSROOT': sdkPath,
    });
  }

  Future<String> createiOSToolchainFile(
    Lib lib,
    IOSCpuType type,
    Map<String, String> env,
  ) async {
    final buildPath = lib.buildPath;
    final toolchainPath = join(
      buildPath,
      type.sdkName(),
      'ios.toolchain.cmake',
    ).file(createWhenNotExists: true);
    final IOSUtils iosUtils = IOSUtils(cpuType: type);

    final sdkPath = await iosUtils.getSdkPath();
    final arch = type.arch();

    final cc = env['CC'];
    final cxx = env['CXX'];

    final toolchainContent = '''
# iOS Toolchain

# Set the target system name
set(CMAKE_SYSTEM_NAME iOS)

# Set the path to the iOS SDK
set(CMAKE_OSX_SYSROOT $sdkPath)

# Set the target CPU architectures
set(CMAKE_OSX_ARCHITECTURES $arch)

# Set the compiler paths and flags
# set(CMAKE_C_COMPILER $cc)
# set(CMAKE_CXX_COMPILER $cxx)
# set(CMAKE_C_FLAGS "\${CMAKE_C_FLAGS} -arch $arch")
# set(CMAKE_CXX_FLAGS "\${CMAKE_CXX_FLAGS} -arch $arch")
''';

    toolchainPath.writeAsStringSync(toolchainContent);
    return toolchainPath.absolute.path;
  }

  Future<void> _compile(
    Lib lib,
    Map<String, String> env,
    String prefix,
    String toolchainPath,
    Map<String, String> params,
  ) async {
    lib.addFlagsToEnv(env);

    final sourceDir = lib.workingPath;
    final host = env['HOST'];
    final buildDir = join(lib.buildPath, host).directory();

    StringBuffer log = StringBuffer();

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

    lib.addFlagsToCmakeArgs(paramMap);

    final args = paramMap.entries
        .map(
          (e) => '-D${e.key}="${e.value}"',
        )
        .join(' ');

    final cmd = 'cmake $args -S $sourceDir -B $buildPath';
    // i('cmd: $cmd');
    await shell.run(cmd, environment: env, workingDirectory: sourceDir);
    await shell.run(
      'make -j8',
      environment: env,
      workingDirectory: buildPath,
    );
    await shell.run(
      'make install',
      environment: env,
      workingDirectory: buildPath,
    );
  }
}
