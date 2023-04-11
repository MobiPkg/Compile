import 'package:compile/compile.dart';

class TemplateCommand extends BaseListCommand {
  @override
  String get commandDescription => 'Create template project.';

  @override
  String get name => 'template';

  @override
  List<String> get aliases => [
        'tmpl',
        'tpl',
        't',
      ];

  @override
  List<BaseTemplateCommand> get subCommands => [];
}

abstract class BaseTemplateCommand extends BaseVoidCommand {
  @override
  void init(ArgParser argParser) {
    super.init(argParser);
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'Project name.',
    );
  }

  @override
  FutureOr<void>? runCommand() async {}
}
