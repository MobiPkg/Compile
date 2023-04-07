import 'package:compile/compile.dart';
import 'package:process_run/shell.dart';

mixin CompileMixin {
  FutureOr<void> compileIOS();
  FutureOr<void> compileAndroid();

  CompileOptions get options => compileOptions;

  FutureOr<void> compile() async {
    if (options.ios) {
      await compileIOS();
    }
    if (options.android) {
      await compileAndroid();
    }
  }

  FutureOr<void> runCmd(String cmd) async {
    print(cmd);
    await run(cmd);
  }

  String get ndkPath {
    return Platform.environment['ANDROID_NDK_HOME']!;
  }
}

abstract class BaseCompiler with CompileMixin {
  BaseCompiler([this.opt]);

  final CompileOptions? opt;

  @override
  CompileOptions get options => opt ?? compileOptions;
}
