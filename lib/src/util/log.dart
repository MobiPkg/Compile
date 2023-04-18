import 'package:compile/compile.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart';

mixin LogMixin {
  late final w = logger.w;
  late final e = logger.e;
  late final i = logger.i;
  late final d = logger.d;
  late final v = logger.v;
  late final wtf = logger.wtf;
  late final log = logger.log;
}

final logger = Logger(
  level: globalOptions.verbose ? Level.verbose : Level.info,
  printer: PrettyPrinter(
    methodCount: 3,
    errorMethodCount: 10,
    printTime: true,
    // noBoxingByDefault: true,
  ),
  filter: ProductionFilter(),
  // filter: DevelopmentFilter(),
  output: ConsoleOutput(),
);

final simpleLogger = Logger(
  level: globalOptions.verbose ? Level.verbose : Level.info,
  printer: SimplePrinter(),
  filter: ProductionFilter(),
  // filter: DevelopmentFilter(),
  output: ConsoleOutput(),
);

typedef CCLoggerFunction = void Function(
  dynamic message, [
  dynamic error,
  StackTrace? stackTrace,
]);

extension CCLoggerExt on Logger {
  CCLoggerFunction get verbose => v;
  CCLoggerFunction get debug => d;
  CCLoggerFunction get info => i;
  CCLoggerFunction get warning => w;
  CCLoggerFunction get error => e;
}

final compilerShellLoggger = CompilerShellLogger();

class CompilerShellLogger {
  final Map<CpuType, StringBuffer> _logMap = {};

  void addLog(CpuType cpuType, String log) {
    final buffer = _logMap[cpuType] ?? StringBuffer();
    buffer.writeln(log);
    _logMap[cpuType] = buffer;
  }

  String getLog(CpuType cpuType) {
    return _logMap[cpuType]?.toString() ?? '';
  }

  void foreachNotEmtpy(void Function(CpuType cpuType, String log) callback) {
    _logMap.forEach((cpuType, buffer) {
      if (buffer.toString().trim().isNotEmpty) {
        callback(cpuType, buffer.toString());
      }
    });
  }
}

void makeCompileShell(
  Lib lib,
  String buildShell,
  CpuType cpuType,
) {
  final srcPath = lib.shellPath;
  final shellName = '${cpuType.platformName()}-${cpuType.cpuName()}';
  final shellPath = join(srcPath, 'build-$shellName.sh');
  final shellFile = File(shellPath);
  shellFile.createSync(recursive: true);

  final shellContent = '''
#!/bin/bash
set -e

$buildShell
''';
  shellFile.writeAsStringSync(shellContent);
  // add execute permission
  shell.chmod(shellPath, '+x');

  logger.i('Write compile shell to $shellPath');

  compilerShellLoggger.addLog(cpuType, shellContent);
}
