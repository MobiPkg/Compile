import 'package:args/command_runner.dart';
import 'package:compile/compile.dart';

class CCommand extends BaseListCommand {
  @override
  String get commandDescription => 'C/C++ compile';

  @override
  String get name => 'c';

  @override
  List<Command<void>> get subCommands => [
        AutoToolsCommand(),
      ];
}
