import 'package:args/command_runner.dart';
import 'package:compile/compile.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';

class Commander with LogMixin {
  Commander();

  final CommandRunner<void> _runner = CommandRunner<void>(
    'compile',
    'For compile project',
  );

  final _commanders = <BaseVoidCommand>[
    LibCommand(),
    ProjectCommand(),
    WorkspaceCommand(),
    SupportCommand(),
    TemplateCommand(),
  ];

  CommandRunner<void> get runner => _runner;

  Future<void> run(List<String> args) async {
    try {
      await envs.init();
      _commanders.forEach(runner.addCommand);
      await handleGlobalOptions(runner, args);

      await runner.run(args);
    } on UsageException catch (e, st) {
      final log = '$e\n$st';
      logger.e(log);
    } catch (e, st) {
      logger.e('Happen error:', e, st);
    } finally {
      showReport();
    }
  }

  void showReport() {
    final date = DateTime.now();
    final dateFormat = DateFormat('yyyyMMdd-HHmmss');
    final dateStr = dateFormat.format(date);

    reporter.output((cpuType, reportItem) {
      final dir = envs.originDir.absolute.path;
      final typeDir = join(
        dir,
        'logs',
        'report',
        dateStr,
        cpuType.platformName(),
      );
      final log = join(typeDir, '${cpuType.cpuName()}.log');
      final shell = join(typeDir, '${cpuType.cpuName()}.sh');

      final logFile = log.file(createWhenNotExists: true);
      final shellFile = shell.file(createWhenNotExists: true);

      logFile.writeAsStringSync(reportItem.log.toString());
      shellFile.writeAsStringSync(reportItem.command.toString());
    });
  }
}
