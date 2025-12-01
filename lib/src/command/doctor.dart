import 'package:compile/compile.dart';
import 'package:path/path.dart';

/// Doctor 命令 - 检测编译环境
class DoctorCommand extends BaseVoidCommand {
  @override
  String get commandDescription => 'Check build environment for iOS/Android';

  @override
  String get name => 'doctor';

  @override
  List<String> get aliases => ['d'];

  @override
  FutureOr<void>? runCommand() async {
    final doctor = DoctorChecker();
    await doctor.runCheck();
  }
}

/// 检测结果
class CheckResult {
  final String name;
  final bool isOk;
  final String? version;
  final String? path;
  final String? message;
  final String? installHint;

  CheckResult({
    required this.name,
    required this.isOk,
    this.version,
    this.path,
    this.message,
    this.installHint,
  });
}

/// 检测项分组
class CheckGroup {
  final String name;
  final List<CheckResult> results;

  CheckGroup({
    required this.name,
    required this.results,
  });
}

/// Doctor 检测器
class DoctorChecker {
  /// 是否支持彩色输出
  bool get _supportsColor {
    // 检查 TERM 环境变量
    final term = Platform.environment['TERM'] ?? '';
    if (term.isEmpty || term == 'dumb') {
      return false;
    }

    // 检查 NO_COLOR 环境变量 (https://no-color.org/)
    if (Platform.environment.containsKey('NO_COLOR')) {
      return false;
    }

    // 检查 FORCE_COLOR 环境变量
    if (Platform.environment.containsKey('FORCE_COLOR')) {
      return true;
    }

    // 检查是否在 CI 环境
    if (Platform.environment.containsKey('CI')) {
      // 大部分 CI 支持颜色
      return true;
    }

    // 检查 stdout 是否是终端
    return stdout.hasTerminal;
  }

  // ANSI 颜色代码
  String get _green => _supportsColor ? '\x1B[32m' : '';
  String get _red => _supportsColor ? '\x1B[31m' : '';
  String get _yellow => _supportsColor ? '\x1B[33m' : '';
  String get _cyan => _supportsColor ? '\x1B[36m' : '';
  String get _bold => _supportsColor ? '\x1B[1m' : '';
  String get _reset => _supportsColor ? '\x1B[0m' : '';

  String get _checkMark => _supportsColor ? '${_green}✓$_reset' : '[OK]';
  String get _crossMark => _supportsColor ? '${_red}✗$_reset' : '[MISSING]';
  String get _warnMark => _supportsColor ? '${_yellow}!$_reset' : '[WARN]';

  Future<void> runCheck() async {
    _printHeader();

    final groups = <CheckGroup>[];

    // 根据平台添加检测组
    if (Platform.isMacOS) {
      groups.add(await _checkMacOSEnvironment());
      groups.add(await _checkIOSEnvironment());
    } else if (Platform.isLinux) {
      groups.add(await _checkLinuxEnvironment());
    } else if (Platform.isWindows) {
      groups.add(await _checkWindowsEnvironment());
    }

    // 通用检测
    groups.add(await _checkAndroidEnvironment());
    groups.add(await _checkHarmonyEnvironment());
    groups.add(await _checkBuildTools());
    groups.add(await _checkVersionControlTools());

    // 输出结果
    for (final group in groups) {
      _printGroup(group);
    }

    _printSummary(groups);
  }

  void _printHeader() {
    const width = 50;
    final line = '═' * width;
    final title = 'MobiPkg Doctor';
    final subtitle = 'Environment Check Results';
    final titlePadding = (width - title.length) ~/ 2;
    final subtitlePadding = (width - subtitle.length) ~/ 2;
    
    print('');
    print('$_bold╔$line╗$_reset');
    print('$_bold║$_reset${' ' * titlePadding}$_cyan$title$_reset${' ' * (width - titlePadding - title.length)}$_bold║$_reset');
    print('$_bold╠$line╣$_reset');
    print('$_bold║$_reset${' ' * subtitlePadding}$subtitle${' ' * (width - subtitlePadding - subtitle.length)}$_bold║$_reset');
    print('$_bold╚$line╝$_reset');
    print('');
  }

  void _printGroup(CheckGroup group) {
    print('$_bold[${group.name}]$_reset');

    for (final result in group.results) {
      final mark = result.isOk ? _checkMark : _crossMark;
      final buffer = StringBuffer();
      buffer.write('  $mark ${result.name}');

      if (result.version != null) {
        buffer.write(': ${_cyan}${result.version}$_reset');
      }
      if (result.path != null) {
        buffer.write(' (${result.path})');
      }
      if (result.message != null) {
        if (!result.isOk) {
          buffer.write(' - ${_yellow}${result.message}$_reset');
        } else if (result.version == null && result.path == null) {
          // 对于成功但没有版本和路径的项，显示 message
          buffer.write(' - ${result.message}');
        }
      }
      if (result.installHint != null && !result.isOk) {
        buffer.write('\n      ${_cyan}→ ${result.installHint}$_reset');
      }

      print(buffer.toString());
    }

    print('');
  }

  void _printSummary(List<CheckGroup> groups) {
    var totalOk = 0;
    var totalFailed = 0;

    for (final group in groups) {
      for (final result in group.results) {
        if (result.isOk) {
          totalOk++;
        } else {
          totalFailed++;
        }
      }
    }

    print('─' * 50);
    print('');
    print('$_bold Summary: $_reset$_green$totalOk passed$_reset, '
        '${totalFailed > 0 ? '$_red$totalFailed failed$_reset' : '${_green}0 failed$_reset'}');
    print('');
  }

  /// macOS 特有环境检测
  Future<CheckGroup> _checkMacOSEnvironment() async {
    final results = <CheckResult>[];

    // Xcode Command Line Tools
    results.add(await _checkCommand(
      'Xcode Command Line Tools',
      'xcode-select',
      versionArgs: ['-p'],
      parseVersion: (output) => output.trim(),
    ));

    // Homebrew
    results.add(await _checkCommand(
      'Homebrew',
      'brew',
      versionArgs: ['--version'],
      parseVersion: (output) {
        final match = RegExp(r'Homebrew (\d+\.\d+\.\d+)').firstMatch(output);
        return match?.group(1);
      },
    ));

    return CheckGroup(name: 'macOS Environment', results: results);
  }

  /// iOS 环境检测 (仅 macOS)
  Future<CheckGroup> _checkIOSEnvironment() async {
    final results = <CheckResult>[];

    // Xcode
    results.add(await _checkCommand(
      'Xcode',
      'xcodebuild',
      versionArgs: ['-version'],
      parseVersion: (output) {
        final match = RegExp(r'Xcode (\d+\.\d+\.?\d*)').firstMatch(output);
        return match?.group(1);
      },
    ));

    // xcrun
    results.add(await _checkCommand(
      'xcrun',
      'xcrun',
      versionArgs: ['--version'],
      parseVersion: (output) => output.trim(),
    ));

    // iOS SDK
    final sdkResult = await _checkIOSSDK();
    results.add(sdkResult);

    // iOS Simulator SDK
    final simResult = await _checkIOSSimulatorSDK();
    results.add(simResult);

    return CheckGroup(name: 'iOS Environment', results: results);
  }

  Future<CheckResult> _checkIOSSDK() async {
    try {
      final result = Process.runSync('xcrun', ['--sdk', 'iphoneos', '--show-sdk-path']);
      if (result.exitCode == 0) {
        final path = (result.stdout as String).trim();
        final version = _extractSDKVersion(path);
        return CheckResult(
          name: 'iOS SDK',
          isOk: true,
          version: version,
          path: path,
        );
      }
    } catch (_) {}
    return CheckResult(
      name: 'iOS SDK',
      isOk: false,
      message: 'iOS SDK not found',
    );
  }

  Future<CheckResult> _checkIOSSimulatorSDK() async {
    try {
      final result = Process.runSync('xcrun', ['--sdk', 'iphonesimulator', '--show-sdk-path']);
      if (result.exitCode == 0) {
        final path = (result.stdout as String).trim();
        final version = _extractSDKVersion(path);
        return CheckResult(
          name: 'iOS Simulator SDK',
          isOk: true,
          version: version,
          path: path,
        );
      }
    } catch (_) {}
    return CheckResult(
      name: 'iOS Simulator SDK',
      isOk: false,
      message: 'iOS Simulator SDK not found',
    );
  }

  String? _extractSDKVersion(String sdkPath) {
    // /Applications/Xcode.app/.../iPhoneOS17.0.sdk -> 17.0
    final match = RegExp(r'iPhoneOS(\d+\.\d+)\.sdk|iPhoneSimulator(\d+\.\d+)\.sdk')
        .firstMatch(sdkPath);
    return match?.group(1) ?? match?.group(2);
  }

  /// Linux 环境检测
  Future<CheckGroup> _checkLinuxEnvironment() async {
    final results = <CheckResult>[];

    // GCC
    results.add(await _checkCommand(
      'GCC',
      'gcc',
      versionArgs: ['--version'],
      parseVersion: (output) {
        final match = RegExp(r'gcc.*?(\d+\.\d+\.\d+)').firstMatch(output);
        return match?.group(1);
      },
    ));

    // G++
    results.add(await _checkCommand(
      'G++',
      'g++',
      versionArgs: ['--version'],
      parseVersion: (output) {
        final match = RegExp(r'g\+\+.*?(\d+\.\d+\.\d+)').firstMatch(output);
        return match?.group(1);
      },
    ));

    // Clang (optional)
    results.add(await _checkCommand(
      'Clang',
      'clang',
      versionArgs: ['--version'],
      parseVersion: (output) {
        // 匹配 "clang version x.x.x" 或 "Ubuntu clang version x.x.x"
        final match = RegExp(r'clang version (\d+\.\d+\.\d+)').firstMatch(output);
        return match?.group(1);
      },
      optional: true,
    ));

    return CheckGroup(name: 'Linux Environment', results: results);
  }

  /// Windows 环境检测
  Future<CheckGroup> _checkWindowsEnvironment() async {
    final results = <CheckResult>[];

    // Visual Studio
    results.add(await _checkCommand(
      'Visual Studio Build Tools',
      'cl',
      versionArgs: [],
      parseVersion: (output) => 'detected',
      optional: true,
    ));

    // MSVC
    results.add(await _checkCommand(
      'MSVC',
      'cl.exe',
      versionArgs: [],
      parseVersion: (output) => 'detected',
      optional: true,
    ));

    // MinGW
    results.add(await _checkCommand(
      'MinGW (gcc)',
      'gcc',
      versionArgs: ['--version'],
      parseVersion: (output) {
        final match = RegExp(r'gcc.*?(\d+\.\d+\.\d+)').firstMatch(output);
        return match?.group(1);
      },
      optional: true,
    ));

    return CheckGroup(name: 'Windows Environment', results: results);
  }

  /// Android 环境检测
  Future<CheckGroup> _checkAndroidEnvironment() async {
    final results = <CheckResult>[];
    String? sdkPath;
    String? sdkSource;

    // 1. 优先从环境变量获取 SDK 路径
    for (final key in Consts.androidSdkKeys) {
      final value = Platform.environment[key];
      if (value != null && value.isNotEmpty && Directory(value).existsSync()) {
        sdkPath = value;
        sdkSource = key;
        break;
      }
    }

    // 2. 尝试通过 sdkmanager 路径推断 SDK
    String? sdkmanagerPath;
    if (sdkPath == null) {
      sdkmanagerPath = _whichCommand('sdkmanager');
      if (sdkmanagerPath != null) {
        // sdkmanager 通常在 SDK/cmdline-tools/latest/bin/sdkmanager 或 SDK/tools/bin/sdkmanager
        final binDir = dirname(sdkmanagerPath);
        if (basename(binDir) == 'bin') {
          final toolsDir = dirname(binDir);
          final toolsName = basename(toolsDir);
          if (toolsName == 'latest' || toolsName == 'tools') {
            // cmdline-tools/latest/bin or tools/bin
            final parentDir = dirname(toolsDir);
            final parentName = basename(parentDir);
            if (parentName == 'cmdline-tools') {
              sdkPath = dirname(parentDir);
            } else {
              sdkPath = parentDir;
            }
          }
        }
        if (sdkPath != null && Directory(sdkPath).existsSync()) {
          sdkSource = 'sdkmanager';
        } else {
          sdkPath = null;
        }
      }
    }

    // 3. 尝试通过 adb 路径推断 SDK
    String? adbPath;
    if (sdkPath == null) {
      adbPath = _whichCommand('adb');
      if (adbPath != null) {
        // adb 通常在 SDK/platform-tools/adb
        final platformToolsDir = dirname(adbPath);
        if (basename(platformToolsDir) == 'platform-tools') {
          final potentialSdk = dirname(platformToolsDir);
          if (Directory(potentialSdk).existsSync()) {
            sdkPath = potentialSdk;
            sdkSource = 'adb';
          }
        }
      }
    }

    // 4. Linux 下尝试常见的 SDK 安装路径作为 fallback
    if (sdkPath == null && Platform.isLinux) {
      final fallbackPaths = [
        '/opt/android-sdk',
        '/opt/android-sdk-linux',
        '${Platform.environment['HOME']}/Android/Sdk',
        '${Platform.environment['HOME']}/android-sdk',
      ];
      for (final path in fallbackPaths) {
        if (Directory(path).existsSync()) {
          sdkPath = path;
          sdkSource = 'default path';
          break;
        }
      }
    }

    // 输出 SDK 检测结果
    if (sdkPath != null) {
      results.add(CheckResult(
        name: 'Android SDK',
        isOk: true,
        path: sdkPath,
        message: 'detected from $sdkSource',
      ));
    } else {
      results.add(CheckResult(
        name: 'Android SDK',
        isOk: false,
        message: 'Not found',
        installHint: _getInstallHint('android-sdk'),
      ));
    }

    // 检测 sdkmanager
    if (sdkmanagerPath == null) {
      sdkmanagerPath = _whichCommand('sdkmanager');
    }
    if (sdkmanagerPath == null && sdkPath != null) {
      // 尝试从 SDK 路径查找 sdkmanager
      final possiblePaths = [
        join(sdkPath, 'cmdline-tools', 'latest', 'bin', 'sdkmanager'),
        join(sdkPath, 'tools', 'bin', 'sdkmanager'),
      ];
      for (final p in possiblePaths) {
        if (File(p).existsSync()) {
          sdkmanagerPath = p;
          break;
        }
      }
    }
    if (sdkmanagerPath != null) {
      results.add(CheckResult(
        name: 'sdkmanager',
        isOk: true,
        path: sdkmanagerPath,
      ));
    } else {
      results.add(CheckResult(
        name: 'sdkmanager',
        isOk: false,
        message: 'Not found',
        installHint: _getInstallHint('sdkmanager'),
      ));
    }

    // 检测 adb（从 SDK 路径反推）
    if (adbPath == null) {
      adbPath = _whichCommand('adb');
    }
    // 如果未找到 adb，但有 sdkPath，则尝试 sdkPath/platform-tools/adb
    if (adbPath == null && sdkPath != null) {
      final possibleAdb = join(sdkPath, 'platform-tools', 'adb');
      if (File(possibleAdb).existsSync()) {
        adbPath = possibleAdb;
      }
    }
    if (adbPath != null) {
      String? adbVersion;
      try {
        final versionResult = Process.runSync(adbPath, ['version']);
        final output = (versionResult.stdout as String) + (versionResult.stderr as String);
        final match = RegExp(r'Android Debug Bridge version (\d+\.\d+\.\d+)').firstMatch(output);
        adbVersion = match?.group(1);
      } catch (_) {}

      results.add(CheckResult(
        name: 'adb',
        isOk: true,
        version: adbVersion,
        path: adbPath,
      ));
    } else {
      results.add(CheckResult(
        name: 'adb',
        isOk: false,
        message: 'Not found (optional)',
        installHint: _getInstallHint('adb'),
      ));
    }

    // 检测 NDK
    final ndkHome = Platform.environment[Consts.ndkKey];
    String? activeNdkPath;
    String? activeNdkVersion;
    String? ndkSource;

    if (ndkHome != null && ndkHome.isNotEmpty && Directory(ndkHome).existsSync()) {
      activeNdkPath = ndkHome;
      activeNdkVersion = _getNDKVersion(ndkHome);
      ndkSource = 'ANDROID_NDK_HOME';
    } else if (sdkPath != null) {
      // 从 SDK 目录检测 NDK
      final ndkBaseDir = Directory(join(sdkPath, 'ndk'));
      if (ndkBaseDir.existsSync()) {
        final ndkVersions = _listNdkVersions(ndkBaseDir);
        if (ndkVersions.isNotEmpty) {
          final latestVersion = ndkVersions.last;
          activeNdkPath = join(sdkPath, 'ndk', latestVersion);
          activeNdkVersion = latestVersion;
          ndkSource = 'SDK/ndk';
        }
      }
    }

    if (activeNdkPath != null) {
      results.add(CheckResult(
        name: 'Android NDK',
        isOk: true,
        version: activeNdkVersion,
        path: activeNdkPath,
        message: 'from $ndkSource',
      ));

      // 列出 SDK 目录下所有可用的 NDK 版本
      if (sdkPath != null) {
        final ndkBaseDir = Directory(join(sdkPath, 'ndk'));
        if (ndkBaseDir.existsSync()) {
          final ndkVersions = _listNdkVersions(ndkBaseDir);
          if (ndkVersions.length > 1) {
            results.add(CheckResult(
              name: 'Available NDK versions',
              isOk: true,
              message: ndkVersions.join(', '),
            ));
          }
        }
      }
    } else {
      results.add(CheckResult(
        name: 'Android NDK',
        isOk: false,
        message: 'Not found',
        installHint: _getInstallHint('android-ndk'),
      ));
    }

    return CheckGroup(name: 'Android Environment', results: results);
  }

  /// 使用 which/where 查找命令路径
  String? _whichCommand(String command) {
    try {
      final result = Process.runSync(
        Platform.isWindows ? 'where' : 'which',
        [command],
      );
      if (result.exitCode == 0) {
        return (result.stdout as String).trim().split('\n').first;
      }
    } catch (_) {}
    return null;
  }

  /// 列出 NDK 目录下所有版本
  List<String> _listNdkVersions(Directory ndkBaseDir) {
    final ndkVersions = <String>[];
    for (final entity in ndkBaseDir.listSync()) {
      if (entity is Directory) {
        final name = basename(entity.path);
        if (RegExp(r'^\d+\.\d+\.\d+$').hasMatch(name)) {
          ndkVersions.add(name);
        }
      }
    }
    ndkVersions.sort(_compareVersions);
    return ndkVersions;
  }

  /// 从 SDK 路径检测 NDK
  String? _detectNdkFromSdk(String sdkPath) {
    final ndkBaseDir = Directory(join(sdkPath, 'ndk'));
    if (!ndkBaseDir.existsSync()) {
      return null;
    }

    final ndkVersions = _listNdkVersions(ndkBaseDir);
    if (ndkVersions.isEmpty) {
      return null;
    }

    final latestVersion = ndkVersions.last;
    return join(sdkPath, 'ndk', latestVersion);
  }

  /// 比较版本号
  int _compareVersions(String a, String b) {
    final partsA = a.split('.').map(int.parse).toList();
    final partsB = b.split('.').map(int.parse).toList();

    for (var i = 0; i < partsA.length && i < partsB.length; i++) {
      final cmp = partsA[i].compareTo(partsB[i]);
      if (cmp != 0) return cmp;
    }

    return partsA.length.compareTo(partsB.length);
  }

  String? _getNDKVersion(String ndkPath) {
    // 尝试从 source.properties 读取版本
    final propsFile = File(join(ndkPath, 'source.properties'));
    if (propsFile.existsSync()) {
      final content = propsFile.readAsStringSync();
      final match = RegExp(r'Pkg\.Revision\s*=\s*(\d+\.\d+\.\d+)').firstMatch(content);
      return match?.group(1);
    }
    // 尝试从路径提取版本号
    final pathMatch = RegExp(r'(\d+\.\d+\.\d+)').firstMatch(ndkPath);
    return pathMatch?.group(1);
  }

  /// 获取安装建议
  String? _getInstallHint(String toolName) {
    if (Platform.isMacOS) {
      return _getMacOSInstallHint(toolName);
    } else if (Platform.isLinux) {
      return _getLinuxInstallHint(toolName);
    } else if (Platform.isWindows) {
      return _getWindowsInstallHint(toolName);
    }
    return null;
  }

  String? _getMacOSInstallHint(String toolName) {
    final hints = <String, String>{
      'xcode-select': 'xcode-select --install',
      'brew': '/bin/bash -c "\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"',
      'xcodebuild': 'Install Xcode from App Store',
      'xcrun': 'xcode-select --install',
      'cmake': 'brew install cmake',
      'meson': 'brew install meson',
      'ninja': 'brew install ninja',
      'make': 'xcode-select --install',
      'autoconf': 'brew install autoconf',
      'automake': 'brew install automake',
      'libtool': 'brew install libtool',
      'glibtool': 'brew install libtool',
      'pkg-config': 'brew install pkg-config',
      'git': 'brew install git',
      'curl': 'brew install curl',
      'wget': 'brew install wget',
      'rustc': 'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh',
      'cargo': 'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh',
      'gcc': 'brew install gcc',
      'g++': 'brew install gcc',
      'clang': 'xcode-select --install',
      'android-sdk': 'Install Android Studio or: brew install --cask android-studio',
      'android-ndk': 'sdkmanager "ndk;26.1.10909125" or install via Android Studio',
      'sdkmanager': 'brew install --cask android-commandlinetools',
      'adb': 'brew install android-platform-tools',
    };
    return hints[toolName];
  }

  String? _getLinuxInstallHint(String toolName) {
    // 检测 Linux 发行版
    final isDebian = File('/etc/debian_version').existsSync();
    final isFedora = File('/etc/fedora-release').existsSync();
    final isArch = File('/etc/arch-release').existsSync();

    if (isDebian) {
      return _getDebianInstallHint(toolName);
    } else if (isFedora) {
      return _getFedoraInstallHint(toolName);
    } else if (isArch) {
      return _getArchInstallHint(toolName);
    }
    return _getDebianInstallHint(toolName); // 默认使用 Debian 格式
  }

  String? _getDebianInstallHint(String toolName) {
    final hints = <String, String>{
      'cmake': 'sudo apt install cmake',
      'meson': 'sudo apt install meson',
      'ninja': 'sudo apt install ninja-build',
      'make': 'sudo apt install make',
      'autoconf': 'sudo apt install autoconf',
      'automake': 'sudo apt install automake',
      'libtool': 'sudo apt install libtool',
      'pkg-config': 'sudo apt install pkg-config',
      'git': 'sudo apt install git',
      'curl': 'sudo apt install curl',
      'wget': 'sudo apt install wget',
      'rustc': 'sudo apt install rustup/stable',
      'cargo': 'sudo apt install rustup/stable',
      'gcc': 'sudo apt install build-essential',
      'g++': 'sudo apt install build-essential',
      'clang': 'sudo apt install clang',
      'android-sdk': 'Install Android Studio from https://developer.android.com/studio',
      'android-ndk': 'sdkmanager "ndk;26.1.10909125" or install via Android Studio',
      'sdkmanager': 'sudo apt install android-sdk (or install Android Studio)',
      'adb': 'sudo apt install android-tools-adb',
    };
    return hints[toolName];
  }

  String? _getFedoraInstallHint(String toolName) {
    final hints = <String, String>{
      'cmake': 'sudo dnf install cmake',
      'meson': 'sudo dnf install meson',
      'ninja': 'sudo dnf install ninja-build',
      'make': 'sudo dnf install make',
      'autoconf': 'sudo dnf install autoconf',
      'automake': 'sudo dnf install automake',
      'libtool': 'sudo dnf install libtool',
      'pkg-config': 'sudo dnf install pkgconfig',
      'git': 'sudo dnf install git',
      'curl': 'sudo dnf install curl',
      'wget': 'sudo dnf install wget',
      'rustc': 'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh',
      'cargo': 'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh',
      'gcc': 'sudo dnf install gcc gcc-c++',
      'g++': 'sudo dnf install gcc gcc-c++',
      'clang': 'sudo dnf install clang',
      'android-sdk': 'Install Android Studio from https://developer.android.com/studio',
      'android-ndk': 'sdkmanager "ndk;26.1.10909125" or install via Android Studio',
      'sdkmanager': 'sudo dnf install android-tools (or install Android Studio)',
      'adb': 'sudo dnf install android-tools',
    };
    return hints[toolName];
  }

  String? _getArchInstallHint(String toolName) {
    final hints = <String, String>{
      'cmake': 'sudo pacman -S cmake',
      'meson': 'sudo pacman -S meson',
      'ninja': 'sudo pacman -S ninja',
      'make': 'sudo pacman -S make',
      'autoconf': 'sudo pacman -S autoconf',
      'automake': 'sudo pacman -S automake',
      'libtool': 'sudo pacman -S libtool',
      'pkg-config': 'sudo pacman -S pkgconf',
      'git': 'sudo pacman -S git',
      'curl': 'sudo pacman -S curl',
      'wget': 'sudo pacman -S wget',
      'rustc': 'sudo pacman -S rust',
      'cargo': 'sudo pacman -S rust',
      'gcc': 'sudo pacman -S gcc',
      'g++': 'sudo pacman -S gcc',
      'clang': 'sudo pacman -S clang',
      'android-sdk': 'Install Android Studio from https://developer.android.com/studio',
      'android-ndk': 'sdkmanager "ndk;26.1.10909125" or install via Android Studio',
      'sdkmanager': 'yay -S android-sdk (or install Android Studio)',
      'adb': 'sudo pacman -S android-tools',
    };
    return hints[toolName];
  }

  String? _getWindowsInstallHint(String toolName) {
    final hints = <String, String>{
      'cmake': 'winget install Kitware.CMake or choco install cmake',
      'meson': 'pip install meson',
      'ninja': 'winget install Ninja-build.Ninja or choco install ninja',
      'make': 'choco install make',
      'git': 'winget install Git.Git',
      'curl': 'winget install cURL.cURL',
      'wget': 'choco install wget',
      'rustc': 'winget install Rustlang.Rustup',
      'cargo': 'winget install Rustlang.Rustup',
      'cl': 'Install Visual Studio Build Tools',
      'cl.exe': 'Install Visual Studio Build Tools',
      'gcc': 'Install MSYS2 and run: pacman -S mingw-w64-x86_64-gcc',
      'android-sdk': 'Install Android Studio from https://developer.android.com/studio',
      'android-ndk': 'sdkmanager "ndk;26.1.10909125" or install via Android Studio',
      'sdkmanager': 'Install Android Studio or download cmdline-tools',
      'adb': 'Install via Android Studio SDK Manager',
    };
    return hints[toolName];
  }

  /// HarmonyOS 环境检测
  Future<CheckGroup> _checkHarmonyEnvironment() async {
    final results = <CheckResult>[];

    // HARMONY_NDK_HOME
    final harmonyNdk = Platform.environment[Consts.hmKey];
    if (harmonyNdk != null && harmonyNdk.isNotEmpty && Directory(harmonyNdk).existsSync()) {
      results.add(CheckResult(
        name: 'HARMONY_NDK_HOME',
        isOk: true,
        path: harmonyNdk,
      ));
    } else {
      results.add(CheckResult(
        name: 'HARMONY_NDK_HOME',
        isOk: true, // optional
        message: 'Not set (optional for HarmonyOS)',
        installHint: 'Install DevEco Studio from https://developer.harmonyos.com/',
      ));
    }

    return CheckGroup(name: 'HarmonyOS Environment', results: results);
  }

  /// 构建工具检测
  Future<CheckGroup> _checkBuildTools() async {
    final results = <CheckResult>[];

    // CMake
    results.add(await _checkCommand(
      'cmake',
      'cmake',
      versionArgs: ['--version'],
      parseVersion: (output) {
        final match = RegExp(r'cmake version (\d+\.\d+\.\d+)').firstMatch(output);
        return match?.group(1);
      },
    ));

    // Meson
    results.add(await _checkCommand(
      'meson',
      'meson',
      versionArgs: ['--version'],
      parseVersion: (output) => output.trim(),
    ));

    // Ninja
    results.add(await _checkCommand(
      'ninja',
      'ninja',
      versionArgs: ['--version'],
      parseVersion: (output) => output.trim(),
    ));

    // Make
    results.add(await _checkCommand(
      'make',
      'make',
      versionArgs: ['--version'],
      parseVersion: (output) {
        final match = RegExp(r'GNU Make (\d+\.\d+\.?\d*)').firstMatch(output);
        return match?.group(1);
      },
    ));

    // Autoconf
    results.add(await _checkCommand(
      'autoconf',
      'autoconf',
      versionArgs: ['--version'],
      parseVersion: (output) {
        final match = RegExp(r'autoconf.*?(\d+\.\d+\.?\d*)').firstMatch(output);
        return match?.group(1);
      },
    ));

    // Automake
    results.add(await _checkCommand(
      'automake',
      'automake',
      versionArgs: ['--version'],
      parseVersion: (output) {
        final match = RegExp(r'automake.*?(\d+\.\d+\.?\d*)').firstMatch(output);
        return match?.group(1);
      },
    ));

    // Libtool - 不同平台命令名不同
    // macOS (Homebrew): glibtool, glibtoolize
    // Linux (Debian/Ubuntu): libtoolize
    // Linux (其他): libtool
    String libtoolCmd;
    if (Platform.isMacOS) {
      libtoolCmd = 'glibtool';
    } else {
      // Linux: 先尝试 libtool，如果不存在则尝试 libtoolize
      final libtoolPath = _whichCommand('libtool');
      libtoolCmd = libtoolPath != null ? 'libtool' : 'libtoolize';
    }
    results.add(await _checkCommand(
      'libtool',
      libtoolCmd,
      versionArgs: ['--version'],
      parseVersion: (output) {
        final match = RegExp(r'libtool.*?(\d+\.\d+\.?\d*)').firstMatch(output);
        return match?.group(1);
      },
      installHintKey: 'libtool',
    ));

    // pkg-config
    results.add(await _checkCommand(
      'pkg-config',
      'pkg-config',
      versionArgs: ['--version'],
      parseVersion: (output) => output.trim(),
    ));

    // Rust/Cargo (optional)
    results.add(await _checkCommand(
      'rustc',
      'rustc',
      versionArgs: ['--version'],
      parseVersion: (output) {
        final match = RegExp(r'rustc (\d+\.\d+\.\d+)').firstMatch(output);
        return match?.group(1);
      },
      optional: true,
    ));

    results.add(await _checkCommand(
      'cargo',
      'cargo',
      versionArgs: ['--version'],
      parseVersion: (output) {
        final match = RegExp(r'cargo (\d+\.\d+\.\d+)').firstMatch(output);
        return match?.group(1);
      },
      optional: true,
    ));

    return CheckGroup(name: 'Build Tools', results: results);
  }

  /// 版本控制工具检测
  Future<CheckGroup> _checkVersionControlTools() async {
    final results = <CheckResult>[];

    // Git
    results.add(await _checkCommand(
      'git',
      'git',
      versionArgs: ['--version'],
      parseVersion: (output) {
        final match = RegExp(r'git version (\d+\.\d+\.\d+)').firstMatch(output);
        return match?.group(1);
      },
    ));

    // curl
    results.add(await _checkCommand(
      'curl',
      'curl',
      versionArgs: ['--version'],
      parseVersion: (output) {
        final match = RegExp(r'curl (\d+\.\d+\.\d+)').firstMatch(output);
        return match?.group(1);
      },
    ));

    // wget (optional)
    results.add(await _checkCommand(
      'wget',
      'wget',
      versionArgs: ['--version'],
      parseVersion: (output) {
        final match = RegExp(r'GNU Wget (\d+\.\d+\.?\d*)').firstMatch(output);
        return match?.group(1);
      },
      optional: true,
    ));

    return CheckGroup(name: 'Version Control & Download Tools', results: results);
  }

  /// 通用命令检测
  Future<CheckResult> _checkCommand(
    String name,
    String command, {
    List<String> versionArgs = const [],
    String? Function(String output)? parseVersion,
    bool optional = false,
    String? installHintKey,
  }) async {
    final hintKey = installHintKey ?? command;
    try {
      // 先用 which 检测命令是否存在
      final whichResult = Process.runSync(
        Platform.isWindows ? 'where' : 'which',
        [command],
      );

      if (whichResult.exitCode != 0) {
        return CheckResult(
          name: name,
          isOk: false, // optional 未安装也显示 ✗
          message: optional ? 'Not installed (optional)' : 'Not found',
          installHint: _getInstallHint(hintKey),
        );
      }

      final commandPath = (whichResult.stdout as String).trim().split('\n').first;

      // 获取版本信息 - 使用完整路径
      String? version;
      if (versionArgs.isNotEmpty && parseVersion != null) {
        try {
          final versionResult = Process.runSync(commandPath, versionArgs);
          // 合并 stdout 和 stderr，因为有些工具把版本信息输出到 stderr
          final output = (versionResult.stdout as String) + (versionResult.stderr as String);
          if (output.isNotEmpty) {
            version = parseVersion(output);
          }
        } catch (_) {
          // 忽略版本获取失败
        }
      }

      return CheckResult(
        name: name,
        isOk: true,
        version: version,
        path: commandPath,
      );
    } catch (e) {
      return CheckResult(
        name: name,
        isOk: false, // optional 未安装也显示 ✗
        message: optional ? 'Not installed (optional)' : 'Check failed: $e',
        installHint: _getInstallHint(hintKey),
      );
    }
  }
}
