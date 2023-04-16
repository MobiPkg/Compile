import 'package:args/command_runner.dart';

final globalOptions = GlobalOptions();

class GlobalOptions {
  bool verbose = false;
  bool debug = false;
}

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
  argParser.addFlag(
    'debug',
    abbr: 'd',
    help: 'Make some debug info.',
  );

  final result = argParser.parse(args);

  globalOptions.verbose = result['verbose'] as bool;
  globalOptions.debug = result['debug'] as bool;
}
