import 'package:compile/compile.dart';
import 'package:path/path.dart';

abstract class BaseCompiler {
  /// Check env or command
  ///
  /// If not found, throw [Exception]
  void doCheckEnvAndCommand();

  late int cpuCount = envs.cpuCount;

  FutureOr<void> _precompile(Lib lib) async {
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

  /// Precompile,
  FutureOr<void> doPrecompile(Lib lib);

  FutureOr<void> _compile(Lib lib) async {
    if (compileOptions.android) {
      await compileAndroid(lib);
    }
    if (compileOptions.ios && Platform.isMacOS) {
      if (buildMultiiOSArch) {
        await compileMultiCpuIos(lib);
      } else {
        await compileIOS(lib);
        if (!compileOptions.justMakeShell) _lipoLibWithIos(lib);
      }
    }
  }

  FutureOr<void> compileAndroid(Lib lib) async {
    for (final type in AndroidCpuType.values) {
      final androidUtils = AndroidUtils(targetCpuType: type);
      final env = androidUtils.getEnvMap();
      final installRoot = lib.installPath;
      final prefix = join(installRoot, 'android', type.cpuName());

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
      final prefix = join(installRoot, 'ios', type.cpuName());

      _printEnv(env);
      await doCompileIOS(lib, env, prefix, type);

      if (compileOptions.strip) {
        await iosUtils.stripDynamicLib(prefix);
      }

      _copyLicense(lib, prefix);
    }
  }

  FutureOr<void> compileMultiCpuIos(Lib lib) async {}

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
    final example = Directory(join(iOSPath, firstCpuName.cpuName()));
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
        final cpuPath = join(iOSPath, type.cpuName());
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

  bool get buildMultiiOSArch;

  void _copyLicense(Lib lib, String installPath) {
    final licensePath = lib.licensePath;

    final name = lib.name;

    if (licensePath != null) {
      final srcLicenseFile = File(licensePath);
      final dstPath = join(
        installPath,
        'license',
        '$name-LICENSE',
      );
      if (srcLicenseFile.existsSync()) {
        final dstLicenseFile = File(dstPath);
        final parentPath = dstLicenseFile.parent.absolute.path;

        if (!FileSystemEntity.isDirectorySync(parentPath)) {
          shell.runSync('rm -rf $parentPath');
        }

        if (!dstLicenseFile.parent.existsSync()) {
          dstLicenseFile.parent.createSync(recursive: true);
        }

        dstLicenseFile.createSync(recursive: true);
        dstLicenseFile.writeAsStringSync(srcLicenseFile.readAsStringSync());
        logger.info('Copy $licensePath file to $dstPath');
      } else {
        logger.w('The license file is not exist: $licensePath');
      }
    }
  }

  /// Main method
  FutureOr<void> compile(Lib lib) async {
    doCheckEnvAndCommand();

    // pre compile
    await _precompile(lib);

    await _compile(lib);

    logger.info('Compile done, see ${lib.installPath}');
  }
}

void _printEnv(Map<String, String> env) {
  if (globalOptions.verbose) {
    logger.v('Env:\n${env.debugString()}');
  }
}

void makeCompileShell(Lib lib, String buildShell, CpuType cpuType) {
  final srcPath = lib.shellPath;
  final shellName = '${cpuType.platformName()}-${cpuType.cpuName()}';
  final shellPath = join(srcPath, 'build-$shellName.sh');
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
