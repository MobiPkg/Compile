import 'package:args/command_runner.dart';
import 'package:compile/compile.dart';

final compileOptions = CompileOptions();
final commandOption = CommandOptions();


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
    'android',
    abbr: 'a',
    defaultsTo: true,
    help: 'Print this usage information.',
  );
  argParser.addFlag(
    'ios',
    abbr: 'i',
    defaultsTo: true,
    help: 'Print this usage information.',
  );
  argParser.addOption(
    'project-path',
    abbr: 'C',
    defaultsTo: '.',
    help: 'Set project path.',
  );
  argParser.addFlag(
    'remove-old-source',
    abbr: 'R',
    help: 'Remove old build files before compile.',
  );
  argParser.addFlag(
    'strip',
    abbr: 's',
    defaultsTo: true,
    help: 'Strip symbols for dynamic libraries.',
  );
  argParser.addOption(
    'git-depth',
    abbr: 'd',
    help: 'If use git to download source, set git depth to 1.',
    defaultsTo: "1",
  );

  final result = argParser.parse(args);

  commandOption.verbose = result['verbose'] as bool;
  compileOptions.android = result['android'] as bool;
  compileOptions.ios = result['ios'] as bool;
  compileOptions.projectPath = result['project-path'] as String;
  compileOptions.upload = result['upload'] as bool;
  compileOptions.removeOldSource = result['remove-old-source'] as bool;
  compileOptions.strip = result['strip'] as bool;
  compileOptions.gitDepth = int.parse(result['git-depth'] as String);
}

class CommandOptions {
  bool verbose = false;
}

class CompileOptions {

  bool android = true;

  bool ios = true;

  String projectPath = '.';

  bool upload = false;

  bool removeOldSource = false;

  bool strip = false;

  int gitDepth = 1;

}

final envs = Envs();

class Envs {
  late int cpuCount = Platform.numberOfProcessors;

  Future<void> init() async {}
}
