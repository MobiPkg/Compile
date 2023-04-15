import 'package:compile/compile.dart';
import 'package:path/path.dart';

class CompileCommand extends BaseVoidCommand {
  @override
  List<String> get aliases => ['c', 'comp'];

  @override
  void init(ArgParser argParser) {
    super.init(argParser);
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
      abbr: 'g',
      help: 'If use git to download source, set git depth to 1.',
      defaultsTo: "1",
    );

    argParser.addFlag(
      'just-make-shell',
      abbr: 'j',
      help: 'Just make shell script, not run it. The command is help.',
      hide: true,
    );
    argParser.addOption(
      'install-prefix',
      abbr: 'I',
      help: 'Set install path.',
    );
    argParser.addOption(
      'dependency-prefix',
      abbr: 'p',
      help: 'Set dependencies prefix.',
    );
  }

  @override
  String get commandDescription => 'Compile lib for project.';

  @override
  String get name => 'compile';

  void _checkEnv() {
    if (compileOptions.android) {
      checkEnv(Consts.ndkKey, throwMessage: 'Please set ndk path first.');
    }
    if (compileOptions.ios) {
      checkWhich('xcrun', throwMessage: 'Please install xcode first.');
    }
  }

  @override
  FutureOr<void>? runCommand() async {
    final result = argResults;

    if (result != null) {
      compileOptions.android = result['android'] as bool;
      compileOptions.ios = result['ios'] as bool;
      compileOptions.projectPath = result['project-path'] as String;
      compileOptions.removeOldSource = result['remove-old-source'] as bool;
      compileOptions.strip = result['strip'] as bool;
      compileOptions.gitDepth = int.parse(result['git-depth'] as String);
      compileOptions.justMakeShell = result['just-make-shell'] as bool;
      compileOptions.installPrefix = result['install-prefix'] as String?;
      compileOptions.dependencyPrefix = result['dependency-prefix'] as String?;
    }

    _checkEnv();

    final projectDir = normalize(absolute(compileOptions.projectPath));
    logger.info('Change working directory to $projectDir');
    Directory.current = projectDir;
    final lib = Lib.fromDir(Directory.current);

    // Do check lib.yaml and download source tools.
    lib.analyze();

    // download
    if (compileOptions.removeOldSource) {
      await lib.removeOldSource();
      await lib.removeOldBuild();
    }
    await lib.download();

    final compiler = _createCompiler(lib);
    await compiler.compile(lib);
  }

  BaseCompiler _createCompiler(Lib lib) {
    final type = lib.type;
    switch (type) {
      case LibType.cAutotools:
        return AutoToolsCompiler();
      case LibType.cCmake:
        return CMakeCompiler();
      case LibType.cMeson:
        return MesonCompiler();
    }
  }
}
