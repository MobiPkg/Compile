import 'package:compile/compile.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';

class MesonCommand extends BaseVoidCommand with CompilerCommandMixin, LogMixin {
  @override
  LibType get libType => LibType.cMeson;

  @override
  String get name => 'meson';
  @override
  String get commandDescription => 'Meson compile';

  @override
  bool get hidden => true;

  @override
  void doCheckEnvAndCommand() {
    // check meson
    checkWhich('meson');
    // check ninja
    checkWhich('ninja');
    // check pkg-config
    checkWhich('pkg-config');
  }

  @override
  FutureOr<void> doPrecompile(Lib lib) async {
    final dir = lib.workingPath.directory();
    final upstreamWrapFile = join(dir.path, 'upstream.wrap').file();
    if (upstreamWrapFile.existsSync()) {
      const cmd = 'meson wrap install';
      await shell.run(cmd, workingDirectory: dir.path);
    }
  }

  @override
  FutureOr<void> doCompileAndroid(
    Lib lib,
    Map<String, String> env,
    String prefix,
    AndroidCpuType type,
  ) {
    final crossFileContent = makeAndroidCrossFileContent(type);
    final crossFile = join(lib.buildPath, 'cross-file', 'cross-$type.ini')
        .file(createWhenNotExists: true);
    crossFile.writeAsStringSync(crossFileContent);
    return _compile(lib, env, prefix, crossFile, type);
  }

  @override
  FutureOr<void> doCompileIOS(
    Lib lib,
    Map<String, String> env,
    String prefix,
    IOSCpuType type,
  ) {
    final crossFileContent = makeIOSCrossFileContent(type);
    final crossFile = join(lib.buildPath, 'cross-file', 'cross-$type.ini')
        .file(createWhenNotExists: true);
    crossFile.writeAsStringSync(crossFileContent);
    return _compile(lib, env, prefix, crossFile, type);
  }

  void _setLibrarayPath(
    Map<String, String> params,
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

    params['libdir'] = libPath;
  }

  FutureOr<void> _compile(
    Lib lib,
    Map<String, String> env,
    String prefix,
    File crossFile,
    CpuType cpuType,
  ) async {
    lib.injectEnv(env);
    lib.injectPrefix(env, cpuType);

    // setup meson
    final buildPath = lib.buildPath;

    final crossFilePath = crossFile.absolute.path;

    logger.info('meson install path: $prefix');

    final params = <String, String>{
      'prefix': prefix,
      'cross-file': crossFilePath,
      'buildtype': 'release',
    };

    _setLibrarayPath(params, cpuType);

    final opt = params.entries
        .map((entry) => '--${entry.key}="${entry.value}"')
        .join(' ');

    var cmd = 'meson setup $buildPath $opt';
    await shell.run(cmd, workingDirectory: lib.workingPath, environment: env);

    final cpuCount = envs.cpuCount;

    // build
    cmd = 'ninja -C $buildPath -j $cpuCount';
    await shell.run(cmd, workingDirectory: lib.workingPath, environment: env);

    // install
    cmd = 'ninja -C $buildPath install';
    await shell.run(cmd, workingDirectory: lib.workingPath, environment: env);
  }

  String makeAndroidCrossFileContent(AndroidCpuType cpuType) {
    final androidUtils = AndroidUtils(targetCpuType: cpuType);

    final pkgConfigPath = whichSync('pkg-config');
    if (pkgConfigPath == null) {
      throw Exception('pkg-config not found');
    }

    final content = '''
[host_machine]
system = 'android'
cpu_family = '${cpuType.getMesonCpuFamily()}'
cpu = '${cpuType.getCpuName()}'
endian = 'little'

[properties]
c_ld = 'gold'
cpp_ld = 'gold'
needs_exe_wrapper = false
sys_root = '${androidUtils.sysroot()}'

[binaries]
c =     '${androidUtils.cc()}'
cpp =   '${androidUtils.cxx()}'
ar =    '${androidUtils.ar()}'
strip = '${androidUtils.strip()}'
pkgconfig = '$pkgConfigPath'
''';

    return content;
  }

  String makeIOSCrossFileContent(IOSCpuType cpuType) {
    final iosUtils = IOSUtils(cpuType: cpuType);

    final pkgConfigPath = whichSync('pkg-config');
    if (pkgConfigPath == null) {
      throw Exception('pkg-config not found');
    }

    final content = '''
[host_machine]
;; system = 'darwin'
system = 'ios'
cpu_family = '${cpuType.getMesonCpuFamily()}'
cpu = '${cpuType.getCpuName()}'
endian = 'little'

[properties]
c_ld = 'gold'
cpp_ld = 'gold'
needs_exe_wrapper = true
sys_root = '${iosUtils.sysroot()}'

[binaries]
; c =     '${iosUtils.cc()}'
; cpp =   '${iosUtils.cxx()}'
; ar =    '${iosUtils.ar()}'
; strip = '${iosUtils.strip()}'
; pkgconfig = '$pkgConfigPath'
''';

    return content;
  }

  @override
  bool get buildMultiiOSArch => false;
}

extension _AndroidCpuTypeExt on AndroidCpuType {
  String getMesonCpuFamily() {
    switch (this) {
      case AndroidCpuType.arm64:
        return 'aarch64';
      case AndroidCpuType.arm:
        return 'arm';
      case AndroidCpuType.x86:
        return 'x86';
      case AndroidCpuType.x86_64:
        return 'x86_64';
    }
  }

  String getCpuName() {
    switch (this) {
      case AndroidCpuType.arm64:
        return 'aarch64';
      case AndroidCpuType.arm:
        return 'armv7a';
      case AndroidCpuType.x86:
        return 'i686';
      case AndroidCpuType.x86_64:
        return 'x86_64';
    }
  }
}

extension _IosCpuTypeExt on IOSCpuType {
  String getMesonCpuFamily() {
    switch (this) {
      case IOSCpuType.arm64:
        return 'aarch64';
      case IOSCpuType.x86_64:
        return 'x86_64';
    }
  }

  String getCpuName() {
    switch (this) {
      case IOSCpuType.arm64:
        return 'aarch64';
      case IOSCpuType.x86_64:
        return 'x86_64';
    }
  }
}
