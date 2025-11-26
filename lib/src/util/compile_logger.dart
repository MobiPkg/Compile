import 'dart:io';

import 'package:compile/compile.dart';
import 'package:path/path.dart' as p;

/// 编译日志管理器
/// 用于记录编译过程中的详细信息，便于调试和问题定位
final compileLogger = CompileLogger._();

class CompileLogger {
  CompileLogger._();

  String? _logDir;
  String? _libName;
  CpuType? _currentCpuType;
  final Map<String, File> _logFiles = {};

  /// 初始化日志目录
  void init({
    required String logDir,
    required String libName,
  }) {
    _logDir = logDir;
    _libName = libName;
    _logFiles.clear();

    // 创建日志目录
    final dir = Directory(logDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    // 创建主日志文件
    _getOrCreateLogFile('main');
    
    _log('main', '=' * 60);
    _log('main', 'Compile Log for: $libName');
    _log('main', 'Started at: ${DateTime.now().toIso8601String()}');
    _log('main', 'Log directory: $logDir');
    _log('main', '=' * 60);
    _log('main', '');
  }

  /// 设置当前 CPU 类型
  void setCpuType(CpuType? cpuType) {
    _currentCpuType = cpuType;
    if (cpuType != null) {
      final cpuName = '${cpuType.platformName()}-${cpuType.cpuName()}';
      _getOrCreateLogFile(cpuName);
      _log(cpuName, '');
      _log(cpuName, '=' * 60);
      _log(cpuName, 'CPU Type: $cpuName');
      _log(cpuName, 'Started at: ${DateTime.now().toIso8601String()}');
      _log(cpuName, '=' * 60);
    }
  }

  File _getOrCreateLogFile(String name) {
    if (_logFiles.containsKey(name)) {
      return _logFiles[name]!;
    }

    final logPath = p.join(_logDir!, '$_libName-$name.log');
    final file = File(logPath);
    if (file.existsSync()) {
      file.deleteSync();
    }
    file.createSync(recursive: true);
    _logFiles[name] = file;
    return file;
  }

  void _log(String target, String message) {
    final file = _logFiles[target];
    if (file != null) {
      file.writeAsStringSync('$message\n', mode: FileMode.append);
    }
  }

  String _currentTarget() {
    if (_currentCpuType != null) {
      return '${_currentCpuType!.platformName()}-${_currentCpuType!.cpuName()}';
    }
    return 'main';
  }

  /// 记录阶段开始
  void phase(String phaseName) {
    final target = _currentTarget();
    _log(target, '');
    _log(target, '-' * 40);
    _log(target, '[$phaseName] ${DateTime.now().toIso8601String()}');
    _log(target, '-' * 40);
    _log('main', '[$target] Phase: $phaseName');
  }

  /// 记录命令执行
  void command({
    required String command,
    String? workingDirectory,
    Map<String, String>? environment,
  }) {
    final target = _currentTarget();
    _log(target, '');
    _log(target, '>>> Command:');
    _log(target, command);
    
    if (workingDirectory != null) {
      _log(target, '');
      _log(target, '>>> Working Directory:');
      _log(target, workingDirectory);
    }
    
    if (environment != null && environment.isNotEmpty) {
      _log(target, '');
      _log(target, '>>> Environment:');
      for (final entry in environment.entries) {
        _log(target, '  ${entry.key}="${entry.value}"');
      }
    }
  }

  /// 记录命令输出
  void output(String output) {
    final target = _currentTarget();
    _log(target, '');
    _log(target, '>>> Output:');
    _log(target, output);
  }

  /// 记录信息
  void info(String message) {
    final target = _currentTarget();
    _log(target, '[INFO] $message');
    _log('main', '[$target] $message');
  }

  /// 记录警告
  void warning(String message) {
    final target = _currentTarget();
    _log(target, '[WARN] $message');
    _log('main', '[$target] [WARN] $message');
  }

  /// 记录错误
  void error({
    required String message,
    String? command,
    String? workingDirectory,
    Map<String, String>? environment,
    String? stdout,
    String? stderr,
    int? exitCode,
    String? buildSystem,
    String? logFilePath,
  }) {
    final target = _currentTarget();
    
    _log(target, '');
    _log(target, '!' * 60);
    _log(target, '[ERROR] $message');
    _log(target, '!' * 60);
    
    if (command != null) {
      _log(target, '');
      _log(target, 'Command:');
      _log(target, '  $command');
    }
    
    if (workingDirectory != null) {
      _log(target, '');
      _log(target, 'Working Directory:');
      _log(target, '  $workingDirectory');
    }
    
    if (environment != null && environment.isNotEmpty) {
      _log(target, '');
      _log(target, 'Environment:');
      for (final entry in environment.entries) {
        _log(target, '  ${entry.key}="${entry.value}"');
      }
    }
    
    if (exitCode != null) {
      _log(target, '');
      _log(target, 'Exit Code: $exitCode');
    }
    
    if (stdout != null && stdout.isNotEmpty) {
      _log(target, '');
      _log(target, 'Stdout:');
      _log(target, stdout);
    }
    
    if (stderr != null && stderr.isNotEmpty) {
      _log(target, '');
      _log(target, 'Stderr:');
      _log(target, stderr);
    }
    
    if (buildSystem != null) {
      _log(target, '');
      _log(target, 'Build System: $buildSystem');
      _log(target, '');
      _log(target, _getBuildSystemLogHint(buildSystem, workingDirectory));
    }
    
    if (logFilePath != null) {
      _log(target, '');
      _log(target, 'Build System Log:');
      _log(target, '  $logFilePath');
      
      // 尝试读取并附加构建系统日志
      final logFile = File(logFilePath);
      if (logFile.existsSync()) {
        _log(target, '');
        _log(target, '--- Build System Log Content ---');
        _log(target, logFile.readAsStringSync());
        _log(target, '--- End Build System Log ---');
      }
    }
    
    _log('main', '[$target] [ERROR] $message');
  }

  String _getBuildSystemLogHint(String buildSystem, String? workingDirectory) {
    final buildDir = workingDirectory ?? '.';
    
    switch (buildSystem.toLowerCase()) {
      case 'meson':
        return '''
Meson 错误排查提示:
  1. 查看完整日志: $buildDir/meson-logs/meson-log.txt
  2. 常见问题:
     - 选项类型错误: 检查 meson_options.txt 中选项的 type
     - 依赖未找到: 检查 PKG_CONFIG_PATH 是否正确
     - 交叉编译问题: 检查 cross-file 配置
  3. 重新配置: meson setup --wipe <builddir>
''';
      case 'cmake':
        return '''
CMake 错误排查提示:
  1. 查看完整日志: $buildDir/CMakeFiles/CMakeOutput.log
  2. 查看错误日志: $buildDir/CMakeFiles/CMakeError.log
  3. 常见问题:
     - 依赖未找到: 检查 CMAKE_PREFIX_PATH
     - 工具链问题: 检查 CMAKE_TOOLCHAIN_FILE
  4. 清理重建: rm -rf $buildDir && cmake ...
''';
      case 'autotools':
        return '''
Autotools 错误排查提示:
  1. 查看配置日志: $buildDir/config.log
  2. 常见问题:
     - 依赖未找到: 检查 PKG_CONFIG_PATH 和 --with-* 选项
     - 交叉编译问题: 检查 --host 和 --build 参数
  3. 重新配置: make distclean && ./configure ...
''';
      default:
        return '请检查构建系统的日志文件以获取更多信息。';
    }
  }

  /// 记录编译完成
  void complete({bool success = true}) {
    final target = _currentTarget();
    _log(target, '');
    _log(target, '=' * 60);
    _log(target, success ? 'COMPLETED SUCCESSFULLY' : 'COMPLETED WITH ERRORS');
    _log(target, 'Finished at: ${DateTime.now().toIso8601String()}');
    _log(target, '=' * 60);
    
    _log('main', '[$target] ${success ? "SUCCESS" : "FAILED"}');
  }

  /// 获取日志目录路径
  String? get logDirectory => _logDir;

  /// 打印日志文件位置
  void printLogLocations() {
    if (_logDir == null) return;
    
    print('');
    print('=' * 60);
    print('Compile logs saved to:');
    print('  $_logDir');
    print('');
    print('Log files:');
    for (final entry in _logFiles.entries) {
      print('  - ${entry.value.path}');
    }
    print('=' * 60);
  }
}
