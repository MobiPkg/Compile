import 'package:args/command_runner.dart';
import 'package:compile/compile.dart';

final compileOptions = CompileOptions();
final globalOptions = CommandOptions();

Future<void> handleGlobalOptions(
  CommandRunner<void> runner,
  List<String> args,
) async {
  final argParser = runner.argParser;
  argParser.addFlag(
    'verbose',
    abbr: 'v',
    help: 'Print verbose output.',
  );

  final result = argParser.parse(args);

  globalOptions.verbose = result['verbose'] as bool;
}

class CommandOptions {
  bool verbose = false;
}

class CompileOptions {
  bool android = true;

  bool ios = true;

  String projectPath = '.';

  bool removeOldSource = false;

  bool strip = false;

  int gitDepth = 1;
}

final envs = Envs();

class Envs {
  late int cpuCount = Platform.numberOfProcessors;

  Future<void> init() async {}
}
