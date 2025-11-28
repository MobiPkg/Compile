import 'package:compile/compile.dart';
import 'package:path/path.dart';

class LibCommand extends BaseVoidCommand {
  @override
  void init(ArgParser argParser) {
    super.init(argParser);
    compileOptions.initArgParser(argParser);
  }

  @override
  String get commandDescription => 'Compile lib, and install library.';

  @override
  String get name => 'lib';

  @override
  List<String> get aliases => ['l'];

  void _checkEnv() {
    if (compileOptions.android) {
      NdkUtils.checkAndSetNdk();
    }
    if (compileOptions.ios) {
      checkWhich('xcrun', throwMessage: 'Please install xcode first.');
    }
    if (compileOptions.harmony) {
      checkEnv(Consts.hmKey, throwMessage: 'Please set harmony path first.');
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

    final compiler = createCompiler(lib);
    await compiler.compile(lib);

    // Generate CMake configuration
    if (!compileOptions.justMakeShell) {
      final installDir = compileOptions.installPrefix ?? lib.installPath;
      
      if (compileOptions.android) {
        logger.info('Generating Android CMake configuration...');
        final generator = AndroidCmakeGenerator.fromInstallDir(installDir, lib.name);
        generator.generate();
        logger.info('CMake files generated in $installDir/android/');
      }
      
      if (compileOptions.ios) {
        logger.info('Generating iOS CMake configuration...');
        final generator = IosCmakeGenerator.fromInstallDir(installDir, lib.name);
        generator.generate();
        logger.info('CMake files generated in $installDir/ios/');
      }
    }
  }
}
