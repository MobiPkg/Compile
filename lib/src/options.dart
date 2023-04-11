import 'package:args/command_runner.dart';
import 'package:compile/compile.dart';

final compileOptions = CompileOptions();

class CompileOptions {
  bool verbose = false;

  bool android = true;

  bool ios = true;

  String projectPath = '.';

  bool upload = false;

  bool removeOldSource = false;

  bool strip = false;

  Future<void> handleGlobalOptions(
    CommandRunner<void> runner,
    List<String> args,
  ) async {
    final argParser = runner.argParser;
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      defaultsTo: false,
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
    argParser.addFlag(
      'upload',
      abbr: 'u',
      defaultsTo: false,
      help: 'Upload to gitlab.',
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
      defaultsTo: false,
      help: 'Remove old build files before compile.',
    );
    argParser.addFlag(
      'strip',
      abbr: 's',
      defaultsTo: false,
      help: 'Strip symbols for dynamic libraries.',
    );

    final result = argParser.parse(args);

    verbose = result['verbose'] as bool;
    android = result['android'] as bool;
    ios = result['ios'] as bool;
    projectPath = result['project-path'] as String;
    upload = result['upload'] as bool;
    removeOldSource = result['remove-old-source'] as bool;
    strip = result['strip'] as bool;
  }
}

final envs = Envs();

class Envs {
  late int cpuCount = Platform.numberOfProcessors;

  Future<void> init() async {}
}
