import 'package:compile/compile.dart';
import 'package:path/path.dart';

class CompileCommand extends BaseVoidCommand {
  @override
  List<String> get aliases => ['c', 'comp'];

  @override
  void init(ArgParser argParser) {
    super.init(argParser);
    compileOptions.initArgParser(argParser);
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
    compileOptions.configArgResults(argResults);

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
