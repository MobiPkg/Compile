import 'package:compile/compile.dart';
import 'package:path/path.dart';

mixin CompilerCommandMixin on BaseVoidCommand {
  LibType get libType;

  @override
  void init(ArgParser argParser) {
    super.init(argParser);
    initCompileOption(argParser);
  }

  Future<void> initCompileOption(
    ArgParser argParser,
  ) async {
    argParser.addFlag(
      'android',
      abbr: 'a',
      defaultsTo: true,
      help: 'Print this usage information.',
    );
    argParser.addFlag(
      'ios',
      abbr: 'i',
      defaultsTo: true,
      help: 'Print this usage information.',
    );
    argParser.addOption(
      'project-path',
      abbr: 'C',
      defaultsTo: '.',
      help: 'Set project path.',
    );
    argParser.addFlag(
      'remove-old-source',
      abbr: 'R',
      help: 'Remove old build files before compile.',
    );
    argParser.addFlag(
      'strip',
      abbr: 's',
      defaultsTo: true,
      help: 'Strip symbols for dynamic libraries.',
    );
    argParser.addOption(
      'git-depth',
      abbr: 'g',
      help: 'If use git to download source, set git depth to 1.',
      defaultsTo: "1",
    );

    argParser.addFlag(
      'just-make-shell',
      abbr: 'j',
      help: 'Just make shell script, not run it.',
    );
  }

  /// Check project
  FutureOr<void> checkProject(Lib lib) async {
    if (lib.type != libType) {
      throw Exception(
        'Project type not match, '
        'current project type is ${lib.type}, '
        'But compiler type is $libType',
      );
    }

    await doCheckProject(lib);
  }

  FutureOr<void> doCheckProject(Lib lib) {}

  void doCheckEnvAndCommand() {}

  @override
  Future<void> runCommand() async {
    final result = argResults;

    if (result != null) {
      compileOptions.android = result['android'] as bool;
      compileOptions.ios = result['ios'] as bool;
      compileOptions.projectPath = result['project-path'] as String;
      compileOptions.removeOldSource = result['remove-old-source'] as bool;
      compileOptions.strip = result['strip'] as bool;
      compileOptions.gitDepth = int.parse(result['git-depth'] as String);
      compileOptions.justMakeShell = result['just-make-shell'] as bool;
    }

    doCheckEnvAndCommand();
    final projectDir = normalize(absolute(compileOptions.projectPath));

    logger.info('Change working directory to $projectDir');
    Directory.current = projectDir;
    final lib = Lib.fromDir(Directory.current);
    await checkProject(lib);

    lib.analyze();

    // download
    if (compileOptions.removeOldSource) {
      await lib.removeOldSource();
      await lib.removeOldBuild();
    }
    await lib.download();

    // pre compile
    await precompile(lib);

    await compile(lib);

    logger.info('Compile done, see ${lib.installPath}');
  }

  FutureOr<void> compile(Lib lib) async {
    if (compileOptions.android) {
      await compileAndroid(lib);
    }
    if (compileOptions.ios && Platform.isMacOS) {
      if (buildMultiiOSArch) {
        await compileMultiCpuIos(lib);
      } else {
        await compileIOS(lib);
        _lipoLibWithIos(lib);
      }
    }
  }

  bool get buildMultiiOSArch;

  void _lipoLibWithIos(Lib lib) {
    final installPath = lib.installPath;
    final iOSPath = join(installPath, 'ios');
    final logBuffer = StringBuffer('Lipo lib with ios in $iOSPath');
    // 1. create universal path
    final universalPath = join(iOSPath, Consts.iOSMutilArchName)
      ..directory(createWhenNotExists: true);

    logBuffer.writeln('Create universal path: $universalPath');

    // 2. find first cpu type
    final firstCpuName = IOSCpuType.values.first;
    final example = Directory(join(iOSPath, firstCpuName.installPath()));
    final items = example.listSync();

    if (items.isEmpty) {
      logBuffer.writeln('No items in $example');
      logger.info(logBuffer.toString());
      return;
    }

    // 3. copy all files to universal path, not include lib/**
    for (final item in items) {
      final name = basename(item.path);
      if (name == 'lib') {
        continue;
      } else {
        shell.runSync('cp -r ${item.absolute.path} $universalPath');
        logBuffer.writeln('Copy ${item.absolute.path} to $universalPath');
      }
    }
    // 4. lipo lib
    final targetLibPath = join(universalPath, 'lib')
      ..directory(createWhenNotExists: true);

    void lipoLib(List<File> srcFiles, String dstPath) {
      final srcPaths = srcFiles.map((e) => e.absolute.path).join(' ');
      final cmd = 'lipo -create $srcPaths -output $dstPath';
      shell.runSync('lipo -create $srcPaths -output $dstPath');
      logBuffer.writeln('Lipo lib with cmd: $cmd');
    }

    void lipoSameNameLib(String name) {
      final srcFiles = <File>[];
      for (final type in IOSCpuType.values) {
        final cpuPath = join(iOSPath, type.installPath());
        final cpuLibPath = join(cpuPath, 'lib');
        final cpuLibFile = File(join(cpuLibPath, name));
        if (cpuLibFile.existsSync()) {
          srcFiles.add(cpuLibFile);
        }
      }
      if (srcFiles.isEmpty) {
        return;
      }
      final dstPath = join(targetLibPath, name);
      lipoLib(srcFiles, dstPath);
    }

    final exampleLibPath = join(example.absolute.path, 'lib');
    final exampleLibDir = Directory(exampleLibPath);
    for (final exampleFile in exampleLibDir.listSync()) {
      final name = basename(exampleFile.path);
      if (name.endsWith('.a') || name.endsWith('.dylib')) {
        lipoSameNameLib(name);
      } else {
        // copy to universal path
        shell.runSync('cp -r ${exampleFile.absolute.path} $targetLibPath');
        logBuffer
            .writeln('Copy ${exampleFile.absolute.path} to $targetLibPath');
      }
    }

    logger.info(logBuffer.toString());
  }

  FutureOr<void> compileAndroid(Lib lib) async {
    for (final type in AndroidCpuType.values) {
      final androidUtils = AndroidUtils(targetCpuType: type);
      final env = androidUtils.getEnvMap();
      final installRoot = lib.installPath;
      final prefix = join(installRoot, 'android', type.installPath());

      _printEnv(env);
      await doCompileAndroid(lib, env, prefix, type);

      if (compileOptions.strip) {
        await androidUtils.stripDynamicLib(prefix);
      }

      _copyLicense(lib, prefix);
    }
  }

  FutureOr<void> compileIOS(Lib lib) async {
    for (final type in IOSCpuType.values) {
      final iosUtils = IOSUtils(cpuType: type);
      final env = iosUtils.getEnvMap();
      final installRoot = lib.installPath;
      final prefix = join(installRoot, 'ios', type.installPath());

      _printEnv(env);
      await doCompileIOS(lib, env, prefix, type);

      if (compileOptions.strip) {
        await iosUtils.stripDynamicLib(prefix);
      }

      _copyLicense(lib, prefix);
    }
  }

  FutureOr<void> compileMultiCpuIos(Lib lib) async {}

  void _copyLicense(Lib lib, String installPath) {
    final licensePath = lib.licensePath;

    if (licensePath != null) {
      final srcLicenseFile = File(licensePath);
      if (srcLicenseFile.existsSync()) {
        final dstLicenseFile = File(join(installPath, 'LICENSE'));
        dstLicenseFile.createSync(recursive: true);
        dstLicenseFile.writeAsStringSync(
          srcLicenseFile.readAsStringSync(),
        );
        logger.info('Copy $licensePath file to $installPath');
      } else {
        logger.w('The license file is not exist: $licensePath');
      }
    }
  }

  void _printEnv(Map<String, String> env) {
    if (globalOptions.verbose) {
      i('Env:\n${env.debugString()}');
    }
  }

  FutureOr<void> doCompileAndroid(
    Lib lib,
    Map<String, String> env,
    String prefix,
    AndroidCpuType type,
  );

  FutureOr<void> doCompileIOS(
    Lib lib,
    Map<String, String> env,
    String prefix,
    IOSCpuType type,
  );

  FutureOr<void> precompile(Lib lib) async {
    final preCompile = lib.precompile;
    if (preCompile.isNotEmpty) {
      for (final script in preCompile) {
        await shell.run(script, workingDirectory: lib.workingPath);
      }
    } else {
      logger.i('No precompile script');
    }

    await doPrecompile(lib);
  }

  FutureOr<void> doPrecompile(Lib lib) async {}

  void makeCompileShell(Lib lib, String buildShell, CpuType cpuType) {
    if (!globalOptions.debug) {
      return;
    }

    final srcPath = lib.sourcePath;
    final shellName = '${cpuType.platformName()}-${cpuType.installPath()}';
    final shellPath = join(srcPath, 'shell', 'build-$shellName.sh');
    final shellFile = File(shellPath);
    shellFile.createSync(recursive: true);

    final shellContent = '''
#!/bin/bash
set -e

$buildShell
''';
    shellFile.writeAsStringSync(shellContent);
    // add execute permission
    shell.chmod(shellPath, '+x');

    logger.i('Write compile shell to $shellPath');
  }
}
