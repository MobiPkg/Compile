import 'package:args/command_runner.dart';
import 'package:compile/compile.dart';

class Commander with LogMixin {
  Commander();

  final CommandRunner<void> _runner = CommandRunner<void>(
    'compile',
    'For compile project',
  );

  final _commanders = <BaseVoidCommand>[
    CompileCommand(),
    SupportCommand(),
    TemplateCommand(),
  ];

  CommandRunner<void> get runner => _runner;

  Future<void> run(List<String> args) async {
    try {
      await envs.init();
      _commanders.forEach(runner.addCommand);
      await handleGlobalOptions(runner, args);
      _checkEnv();
      await runner.run(args);
    } on UsageException catch (e, st) {
      final log = '$e\n$st';
      logger.e(log);
    } catch (e, st) {
      logger.e('Happen error:', e, st);
    }
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
