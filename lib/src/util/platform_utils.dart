import 'package:compile/compile.dart';
import 'package:path/path.dart';

mixin CpuType {
  String cpuName();

  String platformName();

  String rustTripleCpuName();

  PlatformUtils get platformUtils;

  String cmakeCpuName();

  List<Directory> getIncludeDirList(Lib lib);

  List<Directory> getLibDirList(Lib lib);

  String get platform => '${platformName()}/${cpuName()}';

  String get singleName => '${platformName()}-${cpuName()}';

  /// When compiling or checking, it will look for library files from the subdirectory `depPrefix/lib`
  /// Find header files from `depPrefix/include`
  String depPrefix() {
    if (compileOptions.dependencyPrefix != null) {
      return '${compileOptions.dependencyPrefix}/$platform';
    }
    if (envs.prefix != null) {
      return '${envs.prefix}/$platform';
    }
    return '';
  }

  /// The target directory for the installation.
  ///
  /// bin: `prefix/bin`
  /// lib: `prefix/lib`
  /// include: `prefix/include`
  String installPrefix(Lib lib) {
    final depPrefix = this.depPrefix();
    if (compileOptions.installPrefix == null) {
      if (depPrefix.isNotEmpty) {
        return depPrefix;
      }
    }

    final prefix = compileOptions.installPrefix ?? depPrefix;
    if (prefix.isNotEmpty) {
      return '$prefix/$platform';
    }

    return '${lib.installPath}/$platform';
  }

  static List<CpuType> values() {
    return [
      ...AndroidCpuType.values,
      ...IOSCpuType.values,
      ...HarmonyCpuType.values,
    ];
  }

  List<String> getIncludeFlags(Lib lib) {
    final includeFlags = <String>[];

    final includeDirs = getIncludeDirList(lib);
    for (final dir in includeDirs) {
      if (dir.existsSync()) {
        includeFlags.add('-I${dir.absolute.path}');
      }
    }

    return includeFlags;
  }

  List<String> getLibFlags(Lib lib) {
    final libFlags = <String>[];

    final libDirs = getLibDirList(lib);
    for (final dir in libDirs) {
      if (dir.existsSync()) {
        libFlags.add('-L${dir.absolute.path}');
      }
    }

    return libFlags;
  }

  List<String> cFlags(Lib lib) {
    final cflags = <String>[];

    cflags.addAll(getIncludeFlags(lib));
    cflags.addAll(getLibFlags(lib));
    cflags.addFlags(lib.cFlags);

    return cflags;
  }

  List<String> ldFlags(Lib lib) {
    final ldflags = <String>[];

    ldflags.addAll(getLibFlags(lib));
    ldflags.addFlags(lib.ldFlags);

    return ldflags;
  }

  List<String> cxxFlags(Lib lib) {
    final cxxflags = <String>[];

    cxxflags.addAll(getIncludeFlags(lib));
    cxxflags.addAll(getLibFlags(lib));
    cxxflags.addFlags(lib.cxxFlags);

    return cxxflags;
  }

  List<String> cppFlags(Lib lib) {
    final cppflags = <String>[];

    cppflags.addAll(getIncludeFlags(lib));
    cppflags.addAll(getLibFlags(lib));
    cppflags.addFlags(lib.cppFlags);

    return cppflags;
  }
}

mixin PlatformUtils {
  String cc();

  String cxx();

  String ar();

  String as();

  String ranlib();

  String strip();

  String nm();

  String ld();

  String host();

  String sysroot();

  Map<String, String> get platformEnvs;

  CpuType get cpuType;

  Map<String, String> getEnvMap() {
    final depPrefix = cpuType.depPrefix();
    // final systemEnv = Map<String, String>.from(Platform.environment);
    return {
      ...platformEnvs,
      if (depPrefix.isNotEmpty) 'PKG_CONFIG_PATH': '$depPrefix/lib/pkgconfig',
      // ...systemEnv,
      'CC': cc(),
      'CXX': cxx(),
      'AR': ar(),
      'AS': as(),
      'RANLIB': ranlib(),
      'STRIP': strip(),
      'NM': nm(),
      'LD': ld(),
      'HOST': host(),
    };
  }

  Future<void> stripDynamicLib(String prefix) async {
    if (compileOptions.justMakeShell) {
      return;
    }

    final sb = StringBuffer();
    final dir = Directory(prefix);
    final files = dir.listSync(recursive: true);
    for (final file in files) {
      if (file is File) {
        final name = basename(file.path);
        if (name.endsWith('.dylib') || name.endsWith('.so')) {
          await stripFile(file);
          sb.writeln('strip ${file.path} success');
        }
      }
    }
    logger.info(sb.toString().trim());
  }

  Future<void> stripFile(File file);
}

enum AndroidCpuType with CpuType {
  arm,
  arm64,
  x86,
  x86_64;

  String getTargetName() {
    switch (this) {
      case AndroidCpuType.arm:
        return 'armv7a-linux-androideabi';
      case AndroidCpuType.arm64:
        return 'aarch64-linux-android';
      case AndroidCpuType.x86:
        return 'i686-linux-android';
      case AndroidCpuType.x86_64:
        return 'x86_64-linux-android';
    }
  }

  @override
  String cpuName() {
    switch (this) {
      case AndroidCpuType.arm:
        return 'armeabi-v7a';
      case AndroidCpuType.arm64:
        return 'arm64-v8a';
      case AndroidCpuType.x86:
        return 'x86';
      case AndroidCpuType.x86_64:
        return 'x86_64';
    }
  }

  String host() {
    switch (this) {
      case AndroidCpuType.arm:
        return 'arm-linux-androideabi';
      case AndroidCpuType.arm64:
        return 'aarch64-linux-android';
      case AndroidCpuType.x86:
        return 'i686-linux-android';
      case AndroidCpuType.x86_64:
        return 'x86_64-linux-android';
    }
  }

  @override
  String platformName() {
    return 'android';
  }

  @override
  String cmakeCpuName() {
    switch (this) {
      case AndroidCpuType.arm:
        return 'armeabi-v7a';
      case AndroidCpuType.arm64:
        return 'arm64-v8a';
      case AndroidCpuType.x86:
        return 'x86';
      case AndroidCpuType.x86_64:
        return 'x86_64';
    }
  }

  @override
  PlatformUtils get platformUtils {
    return AndroidUtils(targetCpuType: this);
  }

  @override
  String rustTripleCpuName() {
    switch (this) {
      case AndroidCpuType.arm:
        return 'armv7-linux-androideabi';
      case AndroidCpuType.arm64:
        return 'aarch64-linux-android';
      case AndroidCpuType.x86:
        return 'i686-linux-android';
      case AndroidCpuType.x86_64:
        return 'x86_64-linux-android';
    }
  }

  @override
  List<Directory> getIncludeDirList(Lib lib) {
    final result = <Directory>[];

    final depPrefix = this.depPrefix();
    if (depPrefix.isNotEmpty) {
      result.add(Directory('$depPrefix/include'));
    }

    // Add NDK include
    final sysRoot = platformUtils.sysroot();
    result.addJoin(sysRoot, 'usr', 'include');
    result.addJoin(sysRoot, 'usr', 'include', host());

    return result;
  }

  @override
  List<Directory> getLibDirList(Lib lib) {
    final result = <Directory>[];

    final depPrefix = this.depPrefix();
    if (depPrefix.isNotEmpty) {
      result.add(Directory('$depPrefix/lib'));
    }

    // Add NDK lib
    final sysRoot = platformUtils.sysroot();
    result.addJoin(sysRoot, 'usr', 'lib', host(), '21');

    return result;
  }

  static List<String> args() {
    return values.map((e) => e.cpuName()).toList();
  }

  static AndroidCpuType from(String name) {
    for (final value in values) {
      if (value.cpuName() == name) {
        return value;
      }
    }
    throw Exception('Not found $name');
  }
}

class AndroidUtils with PlatformUtils {
  final int minSdk;
  final AndroidCpuType targetCpuType;
  final bool useEnvExport;

  @override
  CpuType get cpuType => targetCpuType;

  const AndroidUtils({
    required this.targetCpuType,
    this.minSdk = 21,
    this.useEnvExport = false,
  });

  String get toolchainPath {
    var ndk = Platform.environment[Consts.ndkKey];
    if (ndk == null) {
      throw Exception('Not found $ndk');
    }

    if (useEnvExport) {
      ndk = '\$${Consts.ndkKey}';
    }

    // current platform
    final platform = Platform.isLinux ? 'linux' : 'darwin';

    final toolchain = join(
      ndk,
      'toolchains',
      'llvm',
      'prebuilt',
      '$platform-x86_64',
    );

    return toolchain;
  }

  String get bins {
    final bins = join(toolchainPath, 'bin');
    return bins;
  }

  @override
  String ar() {
    return join(bins, 'llvm-ar');
  }

  @override
  String as() {
    return cc();
  }

  @override
  String cc() {
    final bins = this.bins;
    final ndkName = targetCpuType.getTargetName();
    return join(bins, '$ndkName$minSdk-clang');
  }

  @override
  String cxx() {
    return '${cc()}++';
  }

  @override
  String ld() {
    return join(bins, 'ld.lld');
  }

  @override
  String nm() {
    return join(bins, 'llvm-nm');
  }

  @override
  String ranlib() {
    return join(bins, 'llvm-ranlib');
  }

  @override
  String strip() {
    return join(bins, 'llvm-strip');
  }

  @override
  String host() {
    return targetCpuType.host();
  }

  @override
  Future<void> stripFile(File file) async {
    final strip = this.strip();
    final path = file.absolute.path;
    await shell.run('$strip $path');
  }

  @override
  String sysroot() {
    return join(toolchainPath, 'sysroot');
  }

  @override
  Map<String, String> get platformEnvs => {
        Consts.ndkKey: Platform.environment[Consts.ndkKey]!,
      };
}

enum IOSCpuType with CpuType {
  arm64,
  x86_64;

  static CpuType universal = const _IOSUniversal();

  String xcrunTarget() {
    switch (this) {
      case IOSCpuType.arm64:
        return 'arm64-apple-ios';
      case IOSCpuType.x86_64:
        return 'x86_64-apple-ios';
      // return 'x86-64';
    }
  }

  @override
  String cpuName() {
    return arch();
  }

  @override
  String platformName() {
    return 'ios';
  }

  @override
  String rustTripleCpuName() {
    switch (this) {
      case IOSCpuType.arm64:
        return 'aarch64-apple-ios';
      case IOSCpuType.x86_64:
        return 'x86_64-apple-ios';
    }
  }

  String arch() {
    switch (this) {
      case IOSCpuType.arm64:
        return 'arm64';
      case IOSCpuType.x86_64:
        return 'x86_64';
    }
  }

  @override
  List<Directory> getIncludeDirList(Lib lib) {
    final result = <Directory>[];

    final depPrefix = this.depPrefix();
    if (depPrefix.isNotEmpty) {
      result.add(Directory('$depPrefix/include'));
    }

    // Add SDK include
    final sdk = platformUtils.sysroot();
    result.addJoin(sdk, 'usr', 'include');

    return result;
  }

  @override
  List<Directory> getLibDirList(Lib lib) {
    final result = <Directory>[];

    final depPrefix = this.depPrefix();
    if (depPrefix.isNotEmpty) {
      result.add(Directory('$depPrefix/lib'));
    }

    // Add SDK lib
    final sdk = platformUtils.sysroot();
    result.addJoin(sdk, 'usr', 'lib');

    return result;
  }

  String sdkName() {
    switch (this) {
      case IOSCpuType.arm64:
        return 'iphoneos';
      case IOSCpuType.x86_64:
        return 'iphonesimulator';
    }
  }

  String clangTarget() {
    switch (this) {
      case IOSCpuType.arm64:
        return 'arm64-apple-ios';
      case IOSCpuType.x86_64:
        return '';
    }
  }

  @override
  String cmakeCpuName() {
    return arch();
  }

  static String cmakeArchsString() {
    final archs = IOSCpuType.values.map((e) => e.arch()).join(';');
    return archs;
  }

  static List<String> args() {
    return values.map((e) => e.cpuName()).toList();
  }

  static IOSCpuType from(String name) {
    for (final value in values) {
      if (value.cpuName() == name) {
        return value;
      }
    }
    throw Exception('Not found $name');
  }

  @override
  PlatformUtils get platformUtils {
    return IOSUtils(cpuType: this);
  }
}

class _IOSUniversal with CpuType {
  const _IOSUniversal();

  @override
  String cpuName() {
    return Consts.iOSMutilArchName;
  }

  @override
  String platformName() {
    return 'ios';
  }

  @override
  String cmakeCpuName() {
    return IOSCpuType.values.map((e) => e.cmakeCpuName()).join(';');
  }

  @override
  String rustTripleCpuName() {
    throw UnimplementedError(
      'The iOS universal architecture is not supported by rust',
    );
  }

  @override
  PlatformUtils get platformUtils {
    throw UnimplementedError(
      'The iOS universal architecture is not supported by rust',
    );
  }

  @override
  List<Directory> getIncludeDirList(Lib lib) {
    // TODO: implement getIncludeDirList
    throw UnimplementedError();
  }

  @override
  List<Directory> getLibDirList(Lib lib) {
    // TODO: implement getLibDirList
    throw UnimplementedError();
  }
}

class IOSUtils with PlatformUtils {
  IOSUtils({
    required this.cpuType,
  });

  @override
  final IOSCpuType cpuType;

  String xcrun(
    String binName, {
    String suffix = "",
  }) {
    final sdkName = cpuType.sdkName();
    return 'xcrun -sdk $sdkName $binName $suffix';
  }

  @override
  String ar() {
    return xcrun('ar');
  }

  @override
  String as() {
    return xcrun('as');
  }

  String get _target {
    final target = cpuType.clangTarget();
    if (target.isEmpty) {
      return '';
    }
    return '-target $target';
  }

  @override
  String cc() {
    return xcrun('clang $_target');
  }

  @override
  String cxx() {
    return xcrun('clang++ $_target');
  }

  @override
  String ld() {
    return xcrun('ld $_target');
  }

  @override
  String nm() {
    return xcrun('nm');
  }

  @override
  String ranlib() {
    return xcrun('ranlib');
  }

  @override
  String strip() {
    return xcrun('strip');
  }

  String getSdkPath() {
    final sdkName = cpuType.sdkName();
    final cmd = 'xcrun --sdk $sdkName --show-sdk-path';
    final result = shell.runSync(cmd);
    return result.trim();
  }

  @override
  String host() {
    switch (cpuType) {
      case IOSCpuType.arm64:
        return 'aarch64-apple-darwin';
      case IOSCpuType.x86_64:
        return 'x86_64-apple-darwin';
    }
  }

  @override
  Future<void> stripFile(File file) async {
    final strip = this.strip();
    final path = file.absolute.path;
    await shell.run('$strip -x -S $path');
  }

  @override
  String sysroot() {
    return getSdkPath();
  }

  @override
  Map<String, String> get platformEnvs => {
        'OBJC': cc(),
        'OBJCXX': cxx(),
      };
}

enum HarmonyCpuType with CpuType {
  arm64,
  arm,
  x86_64;

  @override
  String cpuName() {
    switch (this) {
      case HarmonyCpuType.arm64:
        return 'arm64-v8a';
      case HarmonyCpuType.arm:
        return 'armeabi-v7a';
      case HarmonyCpuType.x86_64:
        return 'x86_64';
    }
  }

  @override
  String platformName() {
    return 'harmony';
  }

  @override
  String rustTripleCpuName() {
    return 'aarch64-unknown-linux-musl';
  }

  @override
  PlatformUtils get platformUtils => HarmonyPlatformUtils(this);

  @override
  String cmakeCpuName() {
    return cpuName();
  }

  String platformTriple() {
    switch (this) {
      case HarmonyCpuType.arm64:
        return 'aarch64-linux-ohos';
      case HarmonyCpuType.arm:
        return 'arm-linux-ohos';
      case HarmonyCpuType.x86_64:
        return 'x86_64-linux-ohos';
    }
  }

  @override
  List<Directory> getIncludeDirList(Lib lib) {
    final result = <Directory>[];

    final depPrefix = this.depPrefix();
    if (depPrefix.isNotEmpty) {
      result.add(Directory('$depPrefix/include'));
    }

    // Add SDK include
    final sdk = platformUtils.sysroot();
    result.addJoin(sdk, 'usr', 'include');
    result.addJoin(sdk, 'usr', 'include', platformTriple());

    return result;
  }

  @override
  List<Directory> getLibDirList(Lib lib) {
    final result = <Directory>[];

    final depPrefix = this.depPrefix();
    if (depPrefix.isNotEmpty) {
      result.add(Directory('$depPrefix/include'));
    }

    // Add SDK include
    final sdk = platformUtils.sysroot();
    result.addJoin(sdk, 'usr', 'lib', platformTriple());

    return result;
  }

  static List<String> args() {
    return values.map((e) => e.cpuName()).toList();
  }

  static HarmonyCpuType from(String value) {
    return values.firstWhere((e) => e.cpuName() == value);
  }
}

class HarmonyPlatformUtils with PlatformUtils {
  @override
  final HarmonyCpuType cpuType;

  HarmonyPlatformUtils(this.cpuType);

  String get bins => join(envs.harmonyNdk, 'llvm', 'bin');

  @override
  String ar() {
    return join(bins, 'llvm-ar');
  }

  @override
  String as() {
    return join(bins, 'llvm-as');
  }

  @override
  String cc() {
    return join(bins, 'clang --target=${cpuType.platformTriple()}');
  }

  @override
  String cxx() {
    return join(bins, 'clang++ --target=${cpuType.platformTriple()}');
  }

  @override
  String host() {
    return cpuType.platformTriple();
  }

  @override
  String ld() {
    return join(bins, 'lld');
  }

  @override
  String nm() {
    return join(bins, 'llvm-nm');
  }

  @override
  Map<String, String> get platformEnvs => {
        'HARMONY_NDK': envs.harmonyNdk,
      };

  @override
  String ranlib() {
    return join(bins, 'llvm-ranlib');
  }

  @override
  String strip() {
    return join(bins, 'llvm-strip');
  }

  @override
  Future<void> stripFile(File file) async {
    final strip = this.strip();
    final path = file.absolute.path;
    await shell.run('$strip -x -S $path');
  }

  @override
  String sysroot() {
    return join(envs.harmonyNdk, 'sysroot');
  }
}
