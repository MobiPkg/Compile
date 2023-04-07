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
      _commanders.forEach(runner.addCommand);
      globalOption(args);
      checkEnv();

      await runner.run(args);
    } on UsageException catch (e, st) {
      print(e);
      print(st);
    } catch (e, st) {
      print('Happen error when run command');
      print(e);
      print(st);
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

    final result = argParser.parse(args);

    compileOptions.verbose = result['verbose'] as bool;
    compileOptions.android = result['android'] as bool;
    compileOptions.ios = result['ios'] as bool;
    compileOptions.projectPath = result['project-path'] as String;
    compileOptions.upload = result['upload'] as bool;
  }

  void checkEnv() {
    final needCheck = <String>[
      'ANDROID_NDK_HOME',
    ];

    void check(String key) {
      final env = Platform.environment[key];
      if (env == null || env.isEmpty) {
        throw Exception('Please set $key');
      }
    }

    for (final envKey in needCheck) {
      check(envKey);
    }

    if (compileOptions.upload) {
      check('GITLAB_TOKEN');
    }
  }
}
