import 'package:compile/compile.dart';
import 'package:path/path.dart';

/// Workspace 编译命令
/// 
/// 用法:
/// ```bash
/// # 编译整个 workspace
/// dart run bin/compile.dart workspace -C path/to/workspace
/// 
/// # 编译指定库及其依赖
/// dart run bin/compile.dart workspace -C path/to/workspace --target libvips
/// ```
class WorkspaceCommand extends BaseVoidCommand {
  @override
  String get commandDescription => 'Compile workspace with dependency resolution';

  @override
  String get name => 'workspace';

  @override
  List<String> get aliases => ['ws', 'w'];

  @override
  void init(ArgParser argParser) {
    super.init(argParser);
    compileOptions.initArgParser(argParser);
    
    argParser.addOption(
      'target',
      abbr: 't',
      help: 'Target library to compile (with its dependencies). '
          'If not specified, all libraries will be compiled.',
    );
  }

  @override
  FutureOr<void>? runCommand() async {
    compileOptions.configArgResults(argResults);

    final workspaceDir = normalize(absolute(compileOptions.projectPath));
    logger.info('Loading workspace from $workspaceDir');
    Directory.current = workspaceDir;

    final workspace = Workspace.fromPath(workspaceDir);
    logger.info('Workspace: ${workspace.name}');
    logger.info('Available libs: ${workspace.libNames.join(', ')}');

    _checkEnv();

    // 获取目标库
    final targetLib = argResults?['target'] as String?;
    
    // 解析依赖并获取编译顺序
    final libs = workspace.resolveDependencies(targetLib: targetLib);
    
    if (libs.isEmpty) {
      logger.w('No libraries to compile');
      return;
    }

    logger.info('Compile order: ${libs.map((e) => e.name).join(' -> ')}');
    logger.info('');

    // 按顺序编译
    for (var i = 0; i < libs.length; i++) {
      final lib = libs[i];
      logger.info('[${ i + 1}/${libs.length}] Compiling ${lib.name}...');
      
      // 分析和下载
      lib.analyze();
      
      if (compileOptions.removeOldSource) {
        await lib.removeOldSource();
        await lib.removeOldBuild();
      }
      await lib.download();

      // 编译
      final compiler = createCompiler(lib);
      await compiler.compile(lib);
      
      logger.info('[${ i + 1}/${libs.length}] ${lib.name} completed');
      logger.info('');
    }

    // 生成 shell 脚本
    if (compileOptions.justMakeShell) {
      final shellPath = join(workspaceDir, 'build', 'shell');
      compilerShellLoggger.foreachNotEmtpy((cpuType, log) {
        final shellFile = join(
          shellPath,
          '${cpuType.platform}-${cpuType.cpuName()}.sh',
        ).file(createWhenNotExists: true);
        shellFile.writeAsStringSync(log);
      });
      logger.info('Shell files generated in $shellPath');
    }

    logger.info('Workspace compilation completed!');
  }

  void _checkEnv() {
    if (compileOptions.android) {
      checkEnv(Consts.ndkKey, throwMessage: 'Please set NDK path first.');
    }
    if (compileOptions.ios) {
      checkWhich('xcrun', throwMessage: 'Please install Xcode first.');
    }
  }
}
