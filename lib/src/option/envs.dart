import 'package:compile/compile.dart';

final envs = Envs();

class Envs {
  late int cpuCount = Platform.numberOfProcessors;

  /// Override environment variables (used for detected NDK path)
  final Map<String, String> _overrideEnvs = {};

  Map<String, String?> get systemEnvs {
    final envs = Map<String, String?>.from(Platform.environment);
    envs.addAll(_overrideEnvs);
    return envs;
  }

  String get script => systemEnvs['_']!;

  String? get prefix => systemEnvs[Consts.prefix];

  String get androidNDK => systemEnvs[Consts.ndkKey]!;

  String get harmonyNdk => systemEnvs[Consts.hmKey]!;

  late Directory originDir;

  /// Set NDK path override (used when auto-detected from SDK)
  void setNdkPath(String path) {
    _overrideEnvs[Consts.ndkKey] = path;
  }

  Future<void> init() async {
    originDir = Directory.current;
  }
}
