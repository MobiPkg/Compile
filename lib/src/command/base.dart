import 'package:args/command_runner.dart';
import 'package:compile/compile.dart';
import 'package:path/path.dart';

abstract class BaseCommand<T> extends Command<T> {
  BaseCommand() {
    init(argParser);
  }

  bool get showAlias => true;

  final command = 'mobipkg';

  @override
  String get description {
    if (showAlias && aliases.isNotEmpty) {
      return '$commandDescription  ( Alias for: ${aliases.join(', ')} )';
    }
    return commandDescription;
  }

  @override
  String? get usageFooter {
    if (showAlias && aliases.isNotEmpty) {
      return '\nAlias for: ${aliases.join(', ')}';
    }
    return null;
  }

  void init(ArgParser argParser) {}

  String get commandDescription;

  @override
  FutureOr<T>? run() {
    try {
      return runCommand();
    } catch (exception, st) {
      return onError(exception, st);
    }
  }

  FutureOr<T>? runCommand();

  FutureOr<T>? onError(Object exception, StackTrace st);
}

abstract class BaseVoidCommand extends BaseCommand<void> {
  @override
  FutureOr<void>? onError(Object exception, StackTrace st) {
    print('Happen error when run command');
    print(exception);
    print(st);
    return null;
  }
}

abstract class BaseListCommand extends BaseVoidCommand {
  List<Command<void>> get subCommands;

  BaseListCommand() {
    subCommands.forEach(addSubcommand);
  }

  @override
  void runCommand() {}
}

mixin CompilerCommandMixin on BaseVoidCommand {
  @override
  Future<void> runCommand() async {
    final projectDir = normalize(absolute(compileOptions.projectPath));

    print('Change working directory to $projectDir');
    Directory.current = projectDir;

    final libFilePath = join(projectDir, 'lib.yaml');
    final libFile = File(libFilePath);
    if (!libFile.existsSync()) {
      throw Exception('Not found lib.yaml in $projectDir');
    }
    final lib = Lib.fromFile(libFile);
    await lib.download(projectDir);
    // download
    await compile();
  }

  FutureOr<void> compile();
}
