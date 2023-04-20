import 'package:compile/compile.dart';
import 'package:path/path.dart';
import 'package:toml/toml.dart';

class RustCompiler extends BaseCompiler {
  @override
  bool get buildMultiiOSArch => false;

  @override
  void doCheckEnvAndCommand(Lib lib) {
    checkWhich('cargo');
    checkWhich('rustup');
    checkWhich('cbindgen');

    final path = lib.workingPath;
    final cargoTomlPath = join(path, 'Cargo.toml');
    final cbingenTomlPath = join(path, 'cbindgen.toml');

    if (!File(cargoTomlPath).existsSync()) {
      throw Exception('Cannot found Cargo.toml in $path');
    }

    if (!File(cbingenTomlPath).existsSync()) {
      throw Exception('Cannot found cbindgen.toml in $path');
    }

    const cmd = 'rustup target list --installed ';
    final tripleCpuNames = shell
        .runSync(cmd)
        .split('\n')
        .where((element) => element.trim().isNotEmpty);

    if (compileOptions.android) {
      checkEnv(Consts.ndkKey, throwMessage: 'Please set ndk path first.');

      for (final cpuType in compileOptions.androidCpuTypes) {
        final tripleCpuName = cpuType.rustTripleCpuName();
        if (!tripleCpuNames.contains(tripleCpuName)) {
          throw Exception(
            'Please install $tripleCpuName first. Run: rustup target add $tripleCpuName',
          );
        }
      }
    }

    if (compileOptions.ios) {
      checkWhich('xcrun', throwMessage: 'Please install xcode first.');
      checkWhich('nasm', throwMessage: 'Please install nasm first.');

      for (final cpuType in IOSCpuType.values) {
        final tripleCpuName = cpuType.rustTripleCpuName();
        if (!tripleCpuNames.contains(tripleCpuName)) {
          throw Exception(
            'Please install $tripleCpuName first. Run: rustup target add $tripleCpuName',
          );
        }
      }
    }
  }

  void createTargetTomlFile(Lib lib) {
    final targetMap = {};
    final map = {'target': targetMap};

    void injectTarget(CpuType cpuType) {
      final utils = cpuType.platformUtils;
      final tripleCpuName = cpuType.rustTripleCpuName();
      // final cc = utils.cc();
      // final parent = dirname(cc);
      // final clang = join(parent, 'clang');
      targetMap[tripleCpuName] = {
        // 'linker': '$clang --target=x86_64-linux-android21',
        // 'linker': utils.cc(),
        'linker':
            '/Users/jinglongcai/code/MobiPkg/compile/logs/NDK/x86_64/bin/clang',
        // 'ar': utils.ar(),
        'ar': utils.cc(),
      };
    }

    if (compileOptions.android) {
      for (final cpuType in compileOptions.androidCpuTypes) {
        injectTarget(cpuType);
      }
    }

    // rust will auto detect ios target
    // if (compileOptions.ios) {
    //   for (final cpuType in IOSCpuType.values) {
    //     injectTarget(cpuType);
    //   }
    // }

    final file = File(join(lib.sourcePath, '..', '.cargo', 'config'));
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    file.writeAsStringSync(TomlDocument.fromMap(map).toString());
  }

  @override
  FutureOr<void> doPrecompile(Lib lib) async {
    createTargetTomlFile(lib);
  }

  @override
  FutureOr<void> doCompileDone(Lib lib) async {}

  @override
  FutureOr<void> doCompileAndroid(
    Lib lib,
    Map<String, String> env,
    String depPrefix,
    String installPrefix,
    AndroidCpuType type,
  ) async {
    final cArgs = lib.cFlags.toList();
    final cxxArgs = lib.cxxFlags.toList();
    final ldArgs = lib.ldFlags.toList();
    final cppArgs = lib.cppFlags.toList();

    var depPrefix = type.depPrefix();

    if (depPrefix.isEmpty) {
      depPrefix = type.installPrefix(lib);
    }

    if (depPrefix.isNotEmpty) {
      cArgs.add('-I$depPrefix/include');
      cxxArgs.add('-I$depPrefix/include');
      ldArgs.add('-L$depPrefix/lib');
    }

    final sysroot = type.platformUtils.sysroot();
    if (sysroot.isNotEmpty) {
      final normalInclude = join(sysroot, 'usr', 'include');
      final platformInclude = join(normalInclude, type.getTargetName());
      final allInclude = [
        normalInclude,
        platformInclude,
      ].map((e) => '-I$e').join(' ');
      cArgs.add(allInclude);
      cxxArgs.add(allInclude);
      ldArgs.add('-L$sysroot/usr/lib/${type.getTargetName()}/21');
    }

    env['CFLAGS'] = [...cppArgs, ...ldArgs, ...cArgs].join(' ');
    env['CXXFLAGS'] = [...cppArgs, ...ldArgs, ...cxxArgs].join(' ');

    await _compile(lib, env, depPrefix, installPrefix, type);
  }

  @override
  FutureOr<void> doCompileIOS(
    Lib lib,
    Map<String, String> env,
    String depPrefix,
    String installPrefix,
    IOSCpuType type,
  ) async {
    await _compile(lib, env, depPrefix, installPrefix, type);
  }

  Future<void> _compile(
    Lib lib,
    Map<String, String> env,
    String depPrefix,
    String installPrefix,
    CpuType type,
  ) async {
    final tripleCpuName = type.rustTripleCpuName();
    final targetPath = join(lib.workingPath, 'target');
    final cmdList = [
      'cargo rustc',
      '--crate-type cdylib',
      // '--crate-type staticlib',
      '--target $tripleCpuName',
      '--target-dir $targetPath',
      '--release',
      '--lib',
    ];

    if (globalOptions.verbose) {
      cmdList.add('-v');
    }

    var cmd = cmdList.join(' ');

    // build
    await shell.run(cmd, workingDirectory: lib.workingPath, environment: env);

    // install
    // 1. create header file
    final headerPath = join(installPrefix, 'include', '${lib.name}.h');
    cmd =
        'cbindgen --config cbindgen.toml --crate ${lib.name} --output $headerPath';
    await shell.run(
      cmd,
      workingDirectory: lib.workingPath,
      environment: env,
    );

    // 2. copy lib file
    final srcLibDir = join(targetPath, tripleCpuName, 'release').directory();
    final dstLibDir = join(installPrefix, 'lib').directory();
    if (!dstLibDir.existsSync()) {
      dstLibDir.createSync(recursive: true);
    }
    logger.info('srcLibDir: $srcLibDir');
    for (final file in srcLibDir.listSync().whereType<File>()) {
      final libFilePath = file.path;
      final fileName = basename(libFilePath);
      if (fileName.endsWith('.a') ||
          fileName.endsWith('.dylib') ||
          fileName.endsWith('.so')) {
        final destPath = join(installPrefix, 'lib');
        await shell.run('cp $libFilePath $destPath');
      }
    }
  }
}
