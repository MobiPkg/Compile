import 'package:compile/compile.dart';

class CMakeCommand extends BaseVoidCommand with CompilerCommandMixin {
  @override
  String get commandDescription => 'CMake compile';

  @override
  LibType get libType => LibType.cCmake;

  @override
  String get name => 'cmake';

  @override
  List<String> get aliases => ['cm'];

  @override
  FutureOr<void> doCheckProject(Lib lib) {}

  @override
  FutureOr<void> doCompileAndroid(
      Lib lib, Map<String, String> env, String prefix) {}

  @override
  FutureOr<void> doCompileIOS(
      Lib lib, Map<String, String> env, String prefix) {}
}
