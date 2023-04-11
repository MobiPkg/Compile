import 'package:args/command_runner.dart';
import 'package:compile/compile.dart';

abstract class BaseCommand<T> extends Command<T> with LogMixin {
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

  late int cpuCount = envs.cpuCount;
}

abstract class BaseVoidCommand extends BaseCommand<void> {
  @override
  FutureOr<void>? onError(Object exception, StackTrace st) {
    simpleLogger.i('Happen error when run command');
    simpleLogger.i(exception);
    simpleLogger.i(st);
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
