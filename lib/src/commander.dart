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
      _checkEnv();

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
    argParser.addFlag(
      'remove-old-source',
      abbr: 'R',
      defaultsTo: false,
      help: 'Remove old build files before compile.',
    );

    final result = argParser.parse(args);

    compileOptions.verbose = result['verbose'] as bool;
    compileOptions.android = result['android'] as bool;
    compileOptions.ios = result['ios'] as bool;
    compileOptions.projectPath = result['project-path'] as String;
    compileOptions.upload = result['upload'] as bool;
    compileOptions.removeOldSource = result['remove-old-source'] as bool;
  }

  void _checkEnv() {
    if (compileOptions.android) {
      checkEnv(Consts.ndkKey, throwMessage: 'Please set ndk path first.');
    }
    if (compileOptions.ios) {
      checkWhich('xcrun', throwMessage: 'Please install xcode first.');
    }
  }
}
