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
      reporter.changeCpuType(null);
    }
    if (compileOptions.ios && Platform.isMacOS) {
      if (buildMultiiOSArch) {
        reporter.changeCpuType(IOSCpuType.universal);
        await compileMultiCpuIos(lib);
        final installPrefix = IOSCpuType.universal.installPrefix(lib);
        _copyLicense(lib, installPrefix);
      } else {
        await compileIOS(lib);
        reporter.changeCpuType(null);
        if (!compileOptions.justMakeShell) _lipoLibWithIos(lib);
      }
    }
    reporter.changeCpuType(null);
  }

  FutureOr<void> compileAndroid(Lib lib) async {
    for (final type in compileOptions.androidCpuTypes) {
      reporter.changeCpuType(type);

      final androidUtils = AndroidUtils(
        targetCpuType: type,
        useEnvExport: compileOptions.justMakeShell,
      );
      final env = androidUtils.getEnvMap();
      _printEnv(env);

      final depPrefix = type.depPrefix();
      final installPrefix = type.installPrefix(lib);

      await doCompileAndroid(
        lib,
        env,
        depPrefix,
        installPrefix,
        type,
      );

      if (compileOptions.strip) {
        await androidUtils.stripDynamicLib(installPrefix);
      }

      _copyLicense(lib, installPrefix);
    }
  }

  FutureOr<void> compileIOS(Lib lib) async {
    for (final type in IOSCpuType.values) {
      reporter.changeCpuType(type);
      final iosUtils = IOSUtils(cpuType: type);
      final env = iosUtils.getEnvMap();

      _printEnv(env);

      final depPrefix = type.depPrefix();
      final installPrefix = type.installPrefix(lib);

      await doCompileIOS(
        lib,
        env,
        depPrefix,
        installPrefix,
        type,
      );

      if (compileOptions.strip) {
        await iosUtils.stripDynamicLib(installPrefix);
      }

      _copyLicense(lib, installPrefix);
    }
  }

  FutureOr<void> compileMultiCpuIos(Lib lib) async {}

  void _lipoLibWithIos(Lib lib) {
    String installPath;

    // 1. get from compileOptions
    if (compileOptions.installPrefix != null) {
      installPath = compileOptions.installPrefix!;
    } else {
      installPath = lib.installPath;
    }

    final iOSPath = join(installPath, 'ios');
    final logBuffer = StringBuffer('Lipo lib with ios in $iOSPath');
    // 1. create universal path
    final universalPath = join(iOSPath, Consts.iOSMutilArchName)
      ..directory(createWhenNotExists: true);

    logBuffer.writeln('Create universal path: $universalPath');

    // 2. find first cpu type
    final firstCpuName = IOSCpuType.values.first;
    final firstCpuDir = Directory(join(iOSPath, firstCpuName.cpuName()));
    final firstCpuChildList = firstCpuDir.listSync();

    if (firstCpuChildList.isEmpty) {
      logBuffer.writeln('No items in $firstCpuDir');
      logger.info(logBuffer.toString());
      return;
    }

    // 3. copy all files to universal path, not include lib/**
    for (final item in firstCpuChildList) {
      final name = basename(item.path);
      if (name == 'lib') {
        continue;
      } else if (name == 'bin') {
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

    final exampleLibPath = join(firstCpuDir.absolute.path, 'lib');
    final exampleLibDir = Directory(exampleLibPath);
    if (exampleLibDir.existsSync()) {
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
      logBuffer.writeln('Lipo lib file done.');
    } else {
      logBuffer.writeln('No lib file in $exampleLibPath');
    }

    logger.info(logBuffer.toString());
  }

  FutureOr<void> doCompileAndroid(
    Lib lib,
    Map<String, String> env,
    String depPrefix,
    String installPrefix,
    AndroidCpuType type,
  );

  FutureOr<void> doCompileIOS(
    Lib lib,
    Map<String, String> env,
    String depPrefix,
    String installPrefix,
    IOSCpuType type,
  );

  /// If true, will call [compileMultiCpuIos] instead of [compileIOS]
  bool get buildMultiiOSArch;

  void _copyLicense(Lib lib, String installPrefix) {
    if (compileOptions.justMakeShell) return;

    final licensePath = lib.licensePath;

    final name = lib.name;

    if (licensePath != null) {
      final srcLicenseFile = File(licensePath);
      final dstPath = join(
        installPrefix,
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

    // apply before pre compile patch
    lib.applyLibPath(
      beforePrecompile: true,
    );

    // pre compile
    await _precompile(lib);

    // apply after pre compile patch
    lib.applyLibPath(
      beforePrecompile: false,
    );

    final matrix = lib.matrixList;

    if (matrix.isEmpty) {
      await _compile(lib);
    } else {
      for (final martixItem in matrix) {
        lib.matrixItem = martixItem;
        await _compile(lib);
      }
    }

    logger.info('Compile done, see ${lib.installPath}');
  }
}

void _printEnv(Map<String, String> env) {
  if (globalOptions.verbose) {
    logger.v('Env:\n${env.debugString()}');
  }
}
