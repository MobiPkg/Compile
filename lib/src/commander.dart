import 'package:args/command_runner.dart';
import 'package:compile/compile.dart';

class Commander {
  Commander();

  final CommandRunner<void> _runner = CommandRunner<void>(
    'compile',
    'For compile project',
  );

  final _commanders = <BaseVoidCommand>[
    CCommand(),
  ];

  CommandRunner<void> get runner => _runner;

  Future<void> run(List<String> args) async {
    try {
      checkEnv();

      _commanders.forEach(runner.addCommand);
      globalOption(args);

      await runner.run(args);
    } on UsageException catch (e, st) {
      print(e);
      print(st);
    } catch (e, st) {
      print('Happen error when run command');
      print(e);
      print(st);
      _runner.usageException(e.toString());
    }
  }

  void globalOption(List<String> args) {
    final argParser = _runner.argParser;
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
    argParser.addOption(
      'project-path',
      abbr: 'C',
      defaultsTo: '.',
      help: 'Set project path.',
    );

    final result = argParser.parse(args);

    compileOptions.verbose = result['verbose'] as bool;
    compileOptions.android = result['android'] as bool;
    compileOptions.ios = result['ios'] as bool;
    compileOptions.projectPath = result['project-path'] as String;
  }

  void checkEnv() {
    final needCheck = <String>[
      'ANDROID_NDK_HOME',
    ];

    for (final envKey in needCheck) {
      final env = Platform.environment[envKey];
      if (env == null || env.isEmpty) {
        throw Exception('Please set $envKey');
      }
    }
  }
}
