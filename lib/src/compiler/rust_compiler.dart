import 'package:compile/compile.dart';
import 'package:path/path.dart';

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

  @override
  FutureOr<void> doPrecompile(Lib lib) {}

  @override
  FutureOr<void> doCompileAndroid(
    Lib lib,
    Map<String, String> env,
    String depPrefix,
    String installPrefix,
    AndroidCpuType type,
  ) {
    // TODO: implement doCompileAndroid
    throw UnimplementedError();
  }

  @override
  FutureOr<void> doCompileIOS(
    Lib lib,
    Map<String, String> env,
    String depPrefix,
    String installPrefix,
    IOSCpuType type,
  ) {
    // TODO: implement doCompileIOS
    throw UnimplementedError();
  }

  Future<void> _compile() async {
    // example cmd: cargo build --target aarch64-apple-ios --target-dir target/ios --release --lib --config 'lib.crate-type = ["staticlib", "cdylib"]'
  }
}
