import 'package:compile/compile.dart';
import 'package:path/path.dart';

class CleanCommand extends BaseVoidCommand {
  @override
  void init(ArgParser argParser) {
    super.init(argParser);
    argParser.addOption(
      'project-path',
      abbr: 'C',
      help: 'Set project path.',
      defaultsTo: '.',
    );
    argParser.addFlag(
      'source',
      abbr: 's',
      help: 'Clean source directories.',
      defaultsTo: true,
    );
    argParser.addFlag(
      'build',
      abbr: 'b',
      help: 'Clean build directories.',
      defaultsTo: true,
    );
    argParser.addFlag(
      'install',
      abbr: 'i',
      help: 'Clean install directories.',
      defaultsTo: false,
    );
    argParser.addFlag(
      'logs',
      abbr: 'l',
      help: 'Clean logs directories.',
      defaultsTo: false,
    );
    argParser.addFlag(
      'deps',
      abbr: 'd',
      help: 'Also clean dependencies (for workspace).',
      defaultsTo: true,
    );
    argParser.addFlag(
      'dry-run',
      help: 'Show what would be deleted without actually deleting.',
      defaultsTo: false,
    );
  }

  @override
  String get commandDescription =>
      'Clean build/source/install directories for lib or workspace.';

  @override
  String get name => 'clean';

  @override
  List<String> get aliases => ['c'];

  bool get cleanSource => argResults?['source'] as bool? ?? true;
  bool get cleanBuild => argResults?['build'] as bool? ?? true;
  bool get cleanInstall => argResults?['install'] as bool? ?? false;
  bool get cleanLogs => argResults?['logs'] as bool? ?? false;
  bool get cleanDeps => argResults?['deps'] as bool? ?? true;
  bool get dryRun => argResults?['dry-run'] as bool? ?? false;

  @override
  FutureOr<void>? runCommand() async {
    final projectPath =
        normalize(absolute(argResults?['project-path'] as String? ?? '.'));
    final projectDir = Directory(projectPath);

    if (!projectDir.existsSync()) {
      logger.e('Project directory not found: $projectPath');
      return;
    }

    Directory.current = projectDir;

    // 检测是 workspace 还是单个 lib
    final isWorkspace = _isWorkspace(projectDir);

    if (isWorkspace) {
      await _cleanWorkspace(projectDir);
    } else {
      await _cleanLib(projectDir);
    }

    logger.i('Clean completed!');
  }

  bool _isWorkspace(Directory dir) {
    final workspaceFiles = ['workspace.yaml', 'workspace.yml'];
    for (final fileName in workspaceFiles) {
      if (File(join(dir.path, fileName)).existsSync()) {
        return true;
      }
    }
    return false;
  }

  Future<void> _cleanWorkspace(Directory workspaceDir) async {
    logger.i('Cleaning workspace: ${workspaceDir.path}');

    final workspace = Workspace.fromDir(workspaceDir);

    // 清理 workspace 级别的 install 目录
    if (cleanInstall) {
      final installDir = Directory(join(workspaceDir.path, 'install'));
      await _deleteDirectory(installDir);
      final installedDir = Directory(join(workspaceDir.path, 'installed'));
      await _deleteDirectory(installedDir);
    }

    // 清理 workspace 级别的 logs 目录
    if (cleanLogs) {
      final logsDir = Directory(join(workspaceDir.path, 'logs'));
      await _deleteDirectory(logsDir);
    }

    // 清理各个 lib
    if (cleanDeps) {
      for (final libRef in workspace.libRefs) {
        final libDir = Directory(join(workspaceDir.path, libRef.path));
        if (libDir.existsSync()) {
          await _cleanLibDir(libDir, libRef.name);
        }
      }
    }
  }

  Future<void> _cleanLib(Directory libDir) async {
    final libFiles = ['lib.yaml', 'lib.yml'];
    bool isLib = false;
    for (final fileName in libFiles) {
      if (File(join(libDir.path, fileName)).existsSync()) {
        isLib = true;
        break;
      }
    }

    if (!isLib) {
      logger.e('Not a valid lib or workspace directory: ${libDir.path}');
      return;
    }

    await _cleanLibDir(libDir, basename(libDir.path));
  }

  Future<void> _cleanLibDir(Directory libDir, String libName) async {
    logger.i('Cleaning lib: $libName');

    if (cleanSource) {
      final sourceDir = Directory(join(libDir.path, 'source'));
      await _deleteDirectory(sourceDir);
    }

    if (cleanBuild) {
      final buildDir = Directory(join(libDir.path, 'build'));
      await _deleteDirectory(buildDir);
    }

    if (cleanInstall) {
      final installDir = Directory(join(libDir.path, 'install'));
      await _deleteDirectory(installDir);
    }

    if (cleanLogs) {
      final logsDir = Directory(join(libDir.path, 'logs'));
      await _deleteDirectory(logsDir);
      // 也清理 build/logs
      final buildLogsDir = Directory(join(libDir.path, 'build', 'logs'));
      await _deleteDirectory(buildLogsDir);
    }
  }

  Future<void> _deleteDirectory(Directory dir) async {
    if (!dir.existsSync()) {
      return;
    }

    final size = await _getDirectorySize(dir);
    final sizeStr = _formatSize(size);

    if (dryRun) {
      logger.i('[DRY-RUN] Would delete: ${dir.path} ($sizeStr)');
    } else {
      logger.i('Deleting: ${dir.path} ($sizeStr)');
      dir.deleteSync(recursive: true);
    }
  }

  Future<int> _getDirectorySize(Directory dir) async {
    int size = 0;
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          size += await entity.length();
        }
      }
    } catch (e) {
      // 忽略权限错误等
    }
    return size;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}
