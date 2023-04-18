import 'package:compile/compile.dart';
import 'package:path/path.dart';

class ProjectCommand extends BaseVoidCommand {
  @override
  String get commandDescription => 'Compile project';

  @override
  String get name => 'project';

  @override
  List<String> get aliases => [
        'p',
        'proj',
      ];

  @override
  void init(ArgParser argParser) {
    super.init(argParser);
    compileOptions.initArgParser(argParser);
  }

  @override
  FutureOr<void>? runCommand() async {
    compileOptions.configArgResults(argResults);

    final projectDir = normalize(absolute(compileOptions.projectPath));
    logger.info('Change working directory to $projectDir');
    Directory.current = projectDir;

    final project = Project.fromDirPath(projectDir);

    _checkEnv();

    for (final lib in project.libs()) {
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

    if (compileOptions.justMakeShell) {
      final projectDebugShellPath = join(projectDir, 'build', 'shell');
      compilerShellLoggger.foreachNotEmtpy((cpuType, log) {
        final shellFile = join(
          projectDebugShellPath,
          '${cpuType.platform}-${cpuType.cpuName()}.sh',
        ).file(createWhenNotExists: true);

        shellFile.writeAsStringSync(log);
      });

      logger.info('Shell files are generated in $projectDebugShellPath.');
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
