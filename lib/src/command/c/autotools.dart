import 'package:compile/compile.dart';

class AutoToolsCommand extends BaseVoidCommand {
  @override
  String get commandDescription => 'AutoTools compile';

  @override
  String get name => 'autotools';

  @override
  List<String> get aliases => ['at', 'a'];

  @override
  FutureOr<void>? runCommand() {
    final compiler = AutoTools();
  }
}
