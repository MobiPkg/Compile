import 'package:args/command_runner.dart';
import 'package:compile/compile.dart';
import 'package:path/path.dart';

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
  argParser.addFlag(
    'debug',
    abbr: 'd',
    help: 'Make some debug info.',
  );

  final result = argParser.parse(args);

  globalOptions.verbose = result['verbose'] as bool;
  globalOptions.debug = result['debug'] as bool;
}

class CommandOptions {
  bool verbose = false;
  bool debug = false;
}

class CompileOptions {
  bool android = true;

  bool ios = true;

  String projectPath = '.';

  bool removeOldSource = false;

  bool strip = false;

  int gitDepth = 1;

  bool justMakeShell = false;

  String? _installPrefix;

  String? get installPrefix => _installPrefix;

  set installPrefix(String? value) {
    if (value != null) {
      final dir = Directory(value).absolute.path;
      _installPrefix = normalize(dir);
    } else {
      _installPrefix = value;
    }
  }
}

final envs = Envs();

class Envs {
  late int cpuCount = Platform.numberOfProcessors;

  Map<String, String?> get systemEnvs => Platform.environment;

  String get script => systemEnvs['_']!;

  String? get prefix => systemEnvs[Consts.prefix];

  String get ndk => systemEnvs[Consts.ndkKey]!;

  Future<void> init() async {}
}
