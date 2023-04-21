import 'package:compile/compile.dart';

class MakefileCompiler extends BaseCompiler {
  @override
  bool get buildMultiiOSArch => false;

  @override
  void doCheckEnvAndCommand(Lib lib) {
    checkWhich('make');
    throw Exception('Not support type: makefile, please use other type');
  }

  @override
  FutureOr<void> doCompileAndroid(
    Lib lib,
    Map<String, String> env,
    String depPrefix,
    String installPrefix,
    AndroidCpuType type,
  ) {
    logger.info('Compile ${lib.name} for Android $type');
  }

  @override
  FutureOr<void> doCompileIOS(
    Lib lib,
    Map<String, String> env,
    String depPrefix,
    String installPrefix,
    IOSCpuType type,
  ) {
    logger.info('Compile ${lib.name} for iOS $type');
  }

  @override
  FutureOr<void> doPrecompile(Lib lib) {}
}
