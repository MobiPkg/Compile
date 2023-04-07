import 'package:compile/compile.dart';

class AutoToolsCommand extends BaseVoidCommand with CompilerCommandMixin {
  @override
  String get commandDescription => 'AutoTools compile';

  @override
  String get name => 'autotools';

  @override
  List<String> get aliases => ['at', 'a'];

  @override
  FutureOr<void> compile() {}
}
