import 'package:compile/compile.dart';
import 'package:path/path.dart';

/// NDK detection utilities
class NdkUtils {
  NdkUtils._();

  /// Try to detect and set ANDROID_NDK_HOME environment variable.
  ///
  /// Detection order:
  /// 1. Check if ANDROID_NDK_HOME is already set
  /// 2. Check ANDROID_SDK_ROOT, ANDROID_HOME, ANDROID_SDK for SDK path
  /// 3. Look for ndk directory under SDK path and find latest version
  ///
  /// Returns the detected NDK path, or null if not found.
  static String? detectAndSetNdk() {
    // 1. Check if already set
    final existingNdk = Platform.environment[Consts.ndkKey];
    if (existingNdk != null && existingNdk.isNotEmpty) {
      final ndkDir = Directory(existingNdk);
      if (ndkDir.existsSync()) {
        return existingNdk;
      }
    }

    // 2. Try to find SDK path from alternative env vars
    String? sdkPath;
    for (final key in Consts.androidSdkKeys) {
      final value = Platform.environment[key];
      if (value != null && value.isNotEmpty) {
        final sdkDir = Directory(value);
        if (sdkDir.existsSync()) {
          sdkPath = value;
          break;
        }
      }
    }

    if (sdkPath == null) {
      return null;
    }

    // 3. Look for ndk directory under SDK path
    final ndkBaseDir = Directory(join(sdkPath, 'ndk'));
    if (!ndkBaseDir.existsSync()) {
      return null;
    }

    // 4. Find the latest NDK version
    final ndkVersions = <String>[];
    for (final entity in ndkBaseDir.listSync()) {
      if (entity is Directory) {
        final name = basename(entity.path);
        // NDK version format: major.minor.build (e.g., 25.2.9519653)
        if (RegExp(r'^\d+\.\d+\.\d+$').hasMatch(name)) {
          ndkVersions.add(name);
        }
      }
    }

    if (ndkVersions.isEmpty) {
      return null;
    }

    // Sort versions and get the latest
    ndkVersions.sort(_compareVersions);
    final latestVersion = ndkVersions.last;
    final ndkPath = join(sdkPath, 'ndk', latestVersion);

    // Set environment variable for current process
    // Note: This only affects the current process, not the shell
    simpleLogger.i('Detected NDK at: $ndkPath');

    return ndkPath;
  }

  /// Compare two version strings (e.g., "25.2.9519653" vs "26.1.10909125")
  static int _compareVersions(String a, String b) {
    final partsA = a.split('.').map(int.parse).toList();
    final partsB = b.split('.').map(int.parse).toList();

    for (var i = 0; i < partsA.length && i < partsB.length; i++) {
      final cmp = partsA[i].compareTo(partsB[i]);
      if (cmp != 0) return cmp;
    }

    return partsA.length.compareTo(partsB.length);
  }

  /// Check if Android NDK is available.
  /// If not directly set, try to detect from SDK path.
  /// Throws exception if NDK is required but not found.
  static void checkAndSetNdk({bool throwOnError = true}) {
    final existingNdk = Platform.environment[Consts.ndkKey];
    if (existingNdk != null && existingNdk.isNotEmpty) {
      final ndkDir = Directory(existingNdk);
      if (ndkDir.existsSync()) {
        return;
      }
    }

    final detectedNdk = detectAndSetNdk();
    if (detectedNdk != null) {
      // Update the system environment map for this process
      envs.setNdkPath(detectedNdk);
      return;
    }

    if (throwOnError) {
      throw Exception(
        'Please set ANDROID_NDK_HOME, or ensure ANDROID_SDK_ROOT/ANDROID_HOME '
        'points to an Android SDK with NDK installed in the ndk/ subdirectory.',
      );
    }
  }
}
