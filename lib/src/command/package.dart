import 'package:args/command_runner.dart';
import 'package:compile/compile.dart';
import 'package:path/path.dart';

/// Package 命令 - 打包编译产物
/// 
/// 用法:
/// ```bash
/// # 从 workspace 创建 XCFramework
/// dart run bin/compile.dart package xcframework -C path/to/workspace --output libvips.xcframework
/// 
/// # 指定目标库
/// dart run bin/compile.dart package xcframework -C path/to/workspace --target libvips
/// ```
class PackageCommand extends BaseListCommand {
  @override
  String get commandDescription => 'Package compiled libraries';

  @override
  String get name => 'package';

  @override
  List<String> get aliases => ['P', 'pkg', 'pack'];

  @override
  List<Command<void>> get subCommands => [
    XCFrameworkCommand(),
  ];
}

/// XCFramework 打包子命令
class XCFrameworkCommand extends BaseVoidCommand {
  @override
  String get commandDescription => 'Create XCFramework from compiled libraries';

  @override
  String get name => 'xcframework';

  @override
  List<String> get aliases => ['xcf', 'xc'];

  @override
  void init(ArgParser argParser) {
    super.init(argParser);
    
    argParser.addOption(
      'project-path',
      abbr: 'C',
      help: 'Path to workspace directory',
      defaultsTo: '.',
    );
    
    argParser.addOption(
      'target',
      abbr: 't',
      help: 'Target library name (main library to package)',
    );
    
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Output XCFramework name (without .xcframework extension)',
    );
    
    argParser.addOption(
      'install-prefix',
      abbr: 'p',
      help: 'Installation prefix where compiled libraries are located',
    );
    
    argParser.addMultiOption(
      'arch',
      abbr: 'a',
      help: 'Architectures to include (arm64, arm64-simulator)',
      defaultsTo: ['arm64', 'arm64-simulator'],
    );
  }

  @override
  FutureOr<void>? runCommand() async {
    final projectPath = normalize(absolute(argResults?['project-path'] as String? ?? '.'));
    final targetLib = argResults?['target'] as String?;
    final outputName = argResults?['output'] as String?;
    final installPrefix = argResults?['install-prefix'] as String?;
    final archs = argResults?['arch'] as List<String>? ?? ['arm64', 'arm64-simulator'];
    
    logger.info('Loading workspace from $projectPath');
    
    // 加载 workspace
    final workspace = Workspace.fromPath(projectPath);
    logger.info('Workspace: ${workspace.name}');
    
    // 确定目标库
    final target = targetLib ?? workspace.libNames.last;
    logger.info('Target library: $target');
    
    // 确定输出名称
    final xcframeworkName = outputName ?? target;
    
    // 确定安装目录
    final installDir = installPrefix ?? join(projectPath, 'install');
    
    // 创建打包器
    final packager = XCFrameworkPackager(
      workspace: workspace,
      targetLib: target,
      installDir: installDir,
      outputName: xcframeworkName,
      outputDir: join(projectPath, 'output'),
      archs: archs,
    );
    
    await packager.package();
  }
}

/// XCFramework 打包器
class XCFrameworkPackager with LogMixin {
  final Workspace workspace;
  final String targetLib;
  final String installDir;
  final String outputName;
  final String outputDir;
  final List<String> archs;

  XCFrameworkPackager({
    required this.workspace,
    required this.targetLib,
    required this.installDir,
    required this.outputName,
    required this.outputDir,
    required this.archs,
  });

  Future<void> package() async {
    logger.info('Creating XCFramework: $outputName');
    logger.info('Install directory: $installDir');
    logger.info('Output directory: $outputDir');
    logger.info('Architectures: ${archs.join(", ")}');
    
    // 收集所有需要打包的库
    final allLibs = _collectLibraries();
    logger.info('Libraries to package: ${allLibs.join(", ")}');
    
    // 创建输出目录
    final outputDirPath = Directory(outputDir);
    if (!outputDirPath.existsSync()) {
      outputDirPath.createSync(recursive: true);
    }
    
    // 为每个架构合并静态库
    final mergedLibs = <String, String>{};
    for (final arch in archs) {
      final archInstallDir = join(installDir, 'ios', arch);
      if (!Directory(archInstallDir).existsSync()) {
        logger.w('Architecture $arch not found in $archInstallDir, skipping');
        continue;
      }
      
      final mergedLib = await _mergeLibraries(arch, archInstallDir, allLibs);
      if (mergedLib != null) {
        mergedLibs[arch] = mergedLib;
      }
    }
    
    if (mergedLibs.isEmpty) {
      throw Exception('No libraries found to package');
    }
    
    // 创建 XCFramework
    await _createXCFramework(mergedLibs);
    
    logger.info('XCFramework created successfully!');
    logger.info('Output: $outputDir/$outputName.xcframework');
  }

  /// 收集所有需要打包的库（包括依赖和 extra_libs）
  List<String> _collectLibraries() {
    final libs = <String>[];
    final visited = <String>{};
    
    void collect(String name) {
      if (visited.contains(name)) return;
      visited.add(name);
      
      if (!workspace.hasLib(name)) {
        // 可能是系统库，跳过
        return;
      }
      
      final lib = workspace.getLib(name);
      
      // 添加主库 - 使用正确的库文件名
      final mainLibName = _getLibFileName(name);
      if (!libs.contains(mainLibName)) {
        libs.add(mainLibName);
      }
      
      // 添加 extra_libs
      for (final extraLib in lib.extraLibs) {
        final extraLibName = extraLib.startsWith('lib') ? extraLib : 'lib$extraLib';
        if (!libs.contains(extraLibName)) {
          libs.add(extraLibName);
        }
      }
      
      // 递归处理依赖
      for (final dep in lib.deps) {
        collect(dep);
      }
    }
    
    collect(targetLib);
    return libs;
  }
  
  /// 获取库的实际文件名（不含 .a 后缀）
  String _getLibFileName(String name) {
    // 特殊映射：workspace 中的名称 -> 实际库文件名
    final mapping = <String, String>{
      'zlib': 'libz',
      'libffi': 'libffi',
      'pcre2': 'libpcre2-8',
      'expat': 'libexpat',
      'glib': 'libglib-2.0',  // glib 的 extra_libs 会添加其他库
      'libjpeg-turbo': 'libjpeg',
      'libpng': 'libpng16',
      'libwebp': 'libwebp',
      'libvips': 'libvips',
    };
    
    return mapping[name] ?? 'lib$name';
  }

  /// 合并指定架构的所有静态库
  Future<String?> _mergeLibraries(
    String arch,
    String archInstallDir,
    List<String> libNames,
  ) async {
    final libDir = join(archInstallDir, 'lib');
    if (!Directory(libDir).existsSync()) {
      logger.w('Library directory not found: $libDir');
      return null;
    }
    
    final existingLibs = <String>[];
    
    for (final libName in libNames) {
      final libPath = join(libDir, '$libName.a');
      if (File(libPath).existsSync()) {
        existingLibs.add(libPath);
        logger.d('  Found: $libName.a');
      } else {
        // 尝试其他命名格式
        final altNames = _getAlternativeLibNames(libName);
        var found = false;
        for (final altName in altNames) {
          final altPath = join(libDir, '$altName.a');
          if (File(altPath).existsSync()) {
            existingLibs.add(altPath);
            logger.d('  Found: $altName.a (alternative for $libName)');
            found = true;
            break;
          }
        }
        if (!found) {
          logger.d('  Not found: $libName.a');
        }
      }
    }
    
    if (existingLibs.isEmpty) {
      logger.w('No libraries found for $arch');
      return null;
    }
    
    logger.info('Merging ${existingLibs.length} libraries for $arch...');
    
    final mergedLib = normalize(absolute(join(outputDir, 'lib$outputName-$arch.a')));
    // 使用绝对路径，避免工作目录问题
    final absoluteLibs = existingLibs.map((e) => normalize(absolute(e))).toList();
    final libsString = absoluteLibs.join(' ');
    
    await shell.run(
      'libtool -static -o $mergedLib $libsString',
    );
    
    logger.info('Merged library: $mergedLib');
    return mergedLib;
  }

  /// 获取库名的替代格式
  List<String> _getAlternativeLibNames(String libName) {
    final result = <String>[];
    
    // libpng -> libpng16
    if (libName == 'libpng') {
      result.add('libpng16');
    }
    
    // libjpeg-turbo -> libjpeg
    if (libName == 'liblibjpeg-turbo' || libName == 'libjpeg-turbo') {
      result.add('libjpeg');
    }
    
    // glib 相关
    if (libName == 'libglib') {
      result.addAll(['libglib-2.0', 'libgio-2.0', 'libgobject-2.0', 'libgmodule-2.0', 'libgthread-2.0']);
    }
    
    // pcre2
    if (libName == 'libpcre2') {
      result.add('libpcre2-8');
    }
    
    return result;
  }

  /// 创建 XCFramework
  Future<void> _createXCFramework(Map<String, String> mergedLibs) async {
    final xcframeworkPath = join(outputDir, '$outputName.xcframework');
    
    // 删除旧的 XCFramework
    final xcframeworkDir = Directory(xcframeworkPath);
    if (xcframeworkDir.existsSync()) {
      xcframeworkDir.deleteSync(recursive: true);
    }
    xcframeworkDir.createSync(recursive: true);
    
    // 为每个架构创建目录并复制文件
    for (final entry in mergedLibs.entries) {
      final arch = entry.key;
      final mergedLib = entry.value;
      
      final archDir = _getXCFrameworkArchDir(arch);
      final archPath = join(xcframeworkPath, archDir);
      Directory(archPath).createSync(recursive: true);
      
      // 复制合并后的库
      final destLib = join(archPath, 'lib$outputName.a');
      File(mergedLib).copySync(destLib);
      
      // 复制头文件
      final headersPath = normalize(absolute(join(archPath, 'Headers')));
      Directory(headersPath).createSync(recursive: true);
      
      final sourceHeadersDir = normalize(absolute(join(installDir, 'ios', arch, 'include')));
      if (Directory(sourceHeadersDir).existsSync()) {
        // 使用 bash -c 来正确处理 glob 展开
        await shell.run('bash -c "cp -r $sourceHeadersDir/* $headersPath/"');
      }
      
      // 复制 glibconfig.h（如果存在）
      final glibConfigDir = normalize(absolute(join(installDir, 'ios', arch, 'lib', 'glib-2.0', 'include')));
      if (Directory(glibConfigDir).existsSync()) {
        final glib2HeadersDir = join(headersPath, 'glib-2.0');
        if (!Directory(glib2HeadersDir).existsSync()) {
          Directory(glib2HeadersDir).createSync(recursive: true);
        }
        await shell.run('bash -c "cp -r $glibConfigDir/* $glib2HeadersDir/"');
      }
    }
    
    // 创建 Info.plist
    _createInfoPlist(xcframeworkPath, mergedLibs.keys.toList());
    
    // 清理临时合并的库文件
    for (final mergedLib in mergedLibs.values) {
      File(mergedLib).deleteSync();
    }
  }

  String _getXCFrameworkArchDir(String arch) {
    switch (arch) {
      case 'arm64':
        return 'ios-arm64';
      case 'arm64-simulator':
        return 'ios-arm64-simulator';
      case 'x86_64':
        return 'ios-x86_64-simulator';
      default:
        return 'ios-$arch';
    }
  }

  void _createInfoPlist(String xcframeworkPath, List<String> archs) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">');
    buffer.writeln('<plist version="1.0">');
    buffer.writeln('<dict>');
    buffer.writeln('    <key>AvailableLibraries</key>');
    buffer.writeln('    <array>');
    
    for (final arch in archs) {
      final archDir = _getXCFrameworkArchDir(arch);
      final isSimulator = arch.contains('simulator') || arch == 'x86_64';
      final cpuArch = arch.replaceAll('-simulator', '');
      
      buffer.writeln('        <dict>');
      buffer.writeln('            <key>HeadersPath</key>');
      buffer.writeln('            <string>Headers</string>');
      buffer.writeln('            <key>LibraryIdentifier</key>');
      buffer.writeln('            <string>$archDir</string>');
      buffer.writeln('            <key>LibraryPath</key>');
      buffer.writeln('            <string>lib$outputName.a</string>');
      buffer.writeln('            <key>SupportedArchitectures</key>');
      buffer.writeln('            <array>');
      buffer.writeln('                <string>$cpuArch</string>');
      buffer.writeln('            </array>');
      buffer.writeln('            <key>SupportedPlatform</key>');
      buffer.writeln('            <string>ios</string>');
      if (isSimulator) {
        buffer.writeln('            <key>SupportedPlatformVariant</key>');
        buffer.writeln('            <string>simulator</string>');
      }
      buffer.writeln('        </dict>');
    }
    
    buffer.writeln('    </array>');
    buffer.writeln('    <key>CFBundlePackageType</key>');
    buffer.writeln('    <string>XFWK</string>');
    buffer.writeln('    <key>XCFrameworkFormatVersion</key>');
    buffer.writeln('    <string>1.0</string>');
    buffer.writeln('</dict>');
    buffer.writeln('</plist>');
    
    final plistPath = join(xcframeworkPath, 'Info.plist');
    File(plistPath).writeAsStringSync(buffer.toString());
  }
}
