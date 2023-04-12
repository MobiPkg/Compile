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
  List<BaseVoidCommand> get subCommands => [
        _SubTemplateCommand(LibType.cAutotools),
        _SubTemplateCommand(LibType.cCmake),
      ];
}

class _SubTemplateCommand extends BaseVoidCommand {
  final LibType type;

  _SubTemplateCommand(this.type);

  @override
  String get commandDescription => 'Create a lib with $name.';

  @override
  String get name => type.value;

  @override
  List<String> get aliases => type.aliases;

  @override
  void init(ArgParser argParser) {
    super.init(argParser);
    argParser.addOption(
      'directory',
      abbr: 'C',
      help: 'Target directory path.',
    );
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'force overwrite target file.',
    );

    argParser.addOption(
      'source-type',
      abbr: 's',
      help: 'Source type.',
      allowed: LibSourceType.values.map((e) => e.value).toList(),
      defaultsTo: LibSourceType.git.value,
    );
  }

  @override
  FutureOr<void>? runCommand() async {
    var directory = argResults!['directory'] as String?;
    if (directory == null) {
      throw Exception('Please specify target directory.');
    }

    directory = Directory(directory).absolute.path;

    final force = argResults!['force'] as bool;
    if (!force && Directory(directory).existsSync()) {
      throw Exception('Target directory is already exists. '
          'If you want to force overwrite, please use --force option.');
    }

    final sourceType = argResults!['source-type'] as String;

    final source = LibSourceType.fromValue(sourceType);

    final template = Template();

    template.writeToDir(targetPath: directory, type: type, sourceType: source);

    logger.info('Created template project in $directory');

    logger.info(
      'Run `compile c ${type.value} -C $directory` to compile project.',
    );
  }
}
