import 'package:compile/compile.dart';
import 'package:path/path.dart';

class MesonCompiler extends BaseCompiler {
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
    String depPrefix,
    String installPrefix,
    AndroidCpuType type,
  ) {
    final crossFileContent = makeAndroidCrossFileContent(lib, type);
    final crossFile = join(lib.buildPath, 'cross-file', 'cross-$type.ini')
        .file(createWhenNotExists: true);
    crossFile.writeAsStringSync(crossFileContent);
    return _compile(lib, env, depPrefix, installPrefix, crossFile, type);
  }

  @override
  FutureOr<void> doCompileIOS(
    Lib lib,
    Map<String, String> env,
    String depPrefix,
    String installPrefix,
    IOSCpuType type,
  ) {
    final crossFileContent = makeIOSCrossFileContent(lib, type);
    final crossFile = join(lib.buildPath, 'cross-file', 'cross-$type.ini')
        .file(createWhenNotExists: true);
    crossFile.writeAsStringSync(crossFileContent);
    return _compile(
      lib,
      env,
      depPrefix,
      installPrefix,
      crossFile,
      type,
    );
  }

  String? _prefix(
    CpuType cpuType,
  ) {
    final prefix = envs.prefix;
    if (prefix == null) {
      return null;
    }

    final libPath = join(
      prefix,
      cpuType.platformName(),
      cpuType.cpuName(),
    );

    return libPath;
  }

  FutureOr<void> _compile(
    Lib lib,
    Map<String, String> env,
    String depPrefix,
    String installPrefix,
    File crossFile,
    CpuType cpuType,
  ) async {
    lib.injectEnv(env);

    // setup meson
    final buildPath = join(
      lib.buildPath,
      cpuType.platformName(),
      cpuType.cpuName(),
    );

    if (buildPath.directory().existsSync()) {
      buildPath.directory().deleteSync(recursive: true);
    }
    buildPath.directory().parent.createSync(recursive: true);

    final crossFilePath = crossFile.absolute.path;

    logger.info('meson install path: $installPrefix');

    final params = <String, String>{
      'prefix': installPrefix,
      'cross-file': crossFilePath,
      'buildtype': 'release',
    };

    final cpuCount = envs.cpuCount;
    var opt = params.entries
        .map((entry) => '--${entry.key}="${entry.value}"')
        .join(' ');

    if (lib.options.isNotEmpty) {
      opt = '$opt ${lib.options.join(' ')}';
    }

    final setupCmd = 'meson setup $buildPath $opt';
    final buildCmd = 'meson compile -C $buildPath -j $cpuCount';
    final installCmd = 'meson install -C $buildPath';

    if (compileOptions.justMakeShell) {
      final shellBuffer = StringBuffer();
      shellBuffer.writeln(env.toEnvString(export: true, separator: '\n'));
      shellBuffer.writeln();
      shellBuffer.writeln('cd ${lib.workingPath}');
      shellBuffer.writeln(setupCmd.formatCommandDefault());
      shellBuffer.writeln(buildCmd);
      shellBuffer.writeln(installCmd);

      makeCompileShell(lib, shellBuffer.toString(), cpuType);
      return;
    }

    await shell.run(
      setupCmd,
      workingDirectory: lib.workingPath,
      environment: env,
    );

    // build
    await shell.run(
      buildCmd,
      workingDirectory: lib.workingPath,
      environment: env,
    );

    // install
    await shell.run(
      installCmd,
      workingDirectory: lib.workingPath,
      environment: env,
    );
  }

  String makeAndroidCrossFileContent(Lib lib, AndroidCpuType cpuType) {
    final androidUtils = AndroidUtils(targetCpuType: cpuType);

    final pkgConfigPath = shell.whichSync('pkg-config');
    if (pkgConfigPath == null) {
      throw Exception('pkg-config not found');
    }

    var prefix = _prefix(cpuType);
    if (prefix == null) {
      prefix = '';
    } else {
      prefix = """
prefix = '$prefix'
""";
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

${_makeBuiltInOptions(lib, cpuType)}

''';

    return content;
  }

  String _makeBuiltInOptions(Lib lib, CpuType cpuType) {
    final cArgs = lib.cFlags.toList();
    final cxxArgs = lib.cxxFlags.toList();
    final ldArgs = lib.ldFlags.toList();
    final cppArgs = lib.cppFlags.toList();

    final depPrefix = cpuType.depPrefix();
    if (depPrefix.isNotEmpty) {
      cArgs.add('-I$depPrefix/include');
      cxxArgs.add('-I$depPrefix/include');
      ldArgs.add('-L$depPrefix/lib');
    }

    final flags = '''
c_args = ${[...cppArgs, ...cArgs].toMesonIniValue()}
cpp_args = ${[...cppArgs, ...cxxArgs].toMesonIniValue()}
c_link_args = ${ldArgs.toMesonIniValue()}
cpp_link_args = ${ldArgs.toMesonIniValue()}
''';

    return '''
[built-in options]
c_std = 'c11'
cpp_std = 'c++11'
$flags
''';
  }

  String makeIOSCrossFileContent(Lib lib, IOSCpuType cpuType) {
    final iosUtils = IOSUtils(cpuType: cpuType);

    final pkgConfigPath = shell.whichSync('pkg-config');
    if (pkgConfigPath == null) {
      throw Exception('pkg-config not found');
    }

    final content = '''
[host_machine]
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

${_makeBuiltInOptions(lib, cpuType)}

b_bitcode = true
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
