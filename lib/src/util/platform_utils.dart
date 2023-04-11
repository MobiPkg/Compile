import 'package:compile/compile.dart';
import 'package:path/path.dart';

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

  Map<String, String> getEnvMap() {
    final systemEnv = Map<String, String>.from(Platform.environment);
    return {
      ...systemEnv,
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

enum AndroidCpuType {
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

  String installName() {
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
}

class AndroidUtils with PlatformUtils {
  final int minSdk;
  final AndroidCpuType targetCpuType;

  const AndroidUtils({
    required this.targetCpuType,
    this.minSdk = 21,
  });

  String get bins {
    final ndk = Platform.environment[Consts.ndkKey];
    if (ndk == null) {
      throw Exception('Not found $ndk');
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

    final bins = join(toolchain, 'bin');
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
}

enum IOSCpuType {
  arm64,
  x86_64;

  String xcrunTarget() {
    switch (this) {
      case IOSCpuType.arm64:
        return 'arm64-apple-ios';
      case IOSCpuType.x86_64:
        return 'x86_64-apple-ios';
      // return 'x86-64';
    }
  }

  String installPath() {
    return arch();
  }

  String arch() {
    switch (this) {
      case IOSCpuType.arm64:
        return 'arm64';
      case IOSCpuType.x86_64:
        return 'x86_64';
    }
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

  Future<String> getSDKPath() {
    return IOSUtils(cpuType: this).getSdkPath();
  }
}

class IOSUtils with PlatformUtils {
  IOSUtils({
    required this.cpuType,
  });

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

  Future<String> getSdkPath() async {
    final sdkName = cpuType.sdkName();
    final cmd = 'xcrun --sdk $sdkName --show-sdk-path';
    final result = await shell.run(cmd);
    return result.map((e) => e.stdout.toString()).join(' ').trim();
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
}
