import 'package:compile/compile.dart';

final envs = Envs();

class Envs {
  late int cpuCount = Platform.numberOfProcessors;

  Map<String, String?> get systemEnvs => Platform.environment;

  String get script => systemEnvs['_']!;

  String? get prefix => systemEnvs[Consts.prefix];

  String get androidNDK => systemEnvs[Consts.ndkKey]!;

  String get harmonyNdk => systemEnvs[Consts.hmKey]!;

  late Directory originDir;

  Future<void> init() async {
    originDir = Directory.current;
  }
}
