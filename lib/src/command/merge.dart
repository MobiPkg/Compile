import 'package:args/command_runner.dart';
import 'package:compile/compile.dart';
import 'package:path/path.dart';

/// Merge command - parent command for merge operations
class MergeCommand extends BaseListCommand {
  @override
  String get commandDescription => 'Merge static libraries to shared libraries';

  @override
  String get name => 'merge';

  @override
  List<String> get aliases => ['m'];

  @override
  List<Command<void>> get subCommands => [
        MergeAndroidCommand(),
      ];
}

/// Android merge subcommand
class MergeAndroidCommand extends BaseVoidCommand {
  @override
  void init(ArgParser argParser) {
    super.init(argParser);
    argParser.addOption(
      'input',
      abbr: 'i',
      help: 'Input directory containing static libraries (.a files)',
      mandatory: true,
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Output directory for shared libraries (.so files)',
      mandatory: true,
    );
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'Output library name (without lib prefix and .so suffix)',
      defaultsTo: 'merged',
    );
    argParser.addOption(
      'mode',
      abbr: 'm',
      help: 'Merge mode: "one-to-one" converts each .a to .so, '
          '"many-to-one" merges all .a into single .so',
      allowed: ['one-to-one', 'many-to-one'],
      defaultsTo: 'many-to-one',
    );
    argParser.addOption(
      'api',
      help: 'Android API level (default: 21)',
      defaultsTo: '21',
    );
    argParser.addMultiOption(
      'exclude',
      abbr: 'e',
      help: 'Library names to exclude (without lib prefix and .a suffix)',
    );
    argParser.addMultiOption(
      'link',
      abbr: 'l',
      help: 'Additional system libraries to link (e.g., log, android, m)',
      defaultsTo: ['log', 'android', 'm'],
    );
    argParser.addFlag(
      'strip',
      help: 'Strip debug symbols from output',
      defaultsTo: true,
    );
    argParser.addFlag(
      'allow-multiple-definition',
      help: 'Allow multiple symbol definitions (use first definition)',
      defaultsTo: false,
    );
  }

  @override
  String get commandDescription =>
      'Convert Android static libraries (.a) to shared libraries (.so)';

  @override
  String get name => 'android';

  @override
  List<String> get aliases => ['a'];

  @override
  FutureOr<void>? runCommand() async {
    NdkUtils.checkAndSetNdk();

    final inputDir = argResults!['input'] as String;
    final outputDir = argResults!['output'] as String;
    final libName = argResults!['name'] as String;
    final mode = argResults!['mode'] as String;
    final apiLevel = int.parse(argResults!['api'] as String);
    final excludeLibs = argResults!['exclude'] as List<String>;
    final linkLibs = argResults!['link'] as List<String>;
    final strip = argResults!['strip'] as bool;
    final allowMultipleDef = argResults!['allow-multiple-definition'] as bool;

    final inputPath = normalize(absolute(inputDir));
    final outputPath = normalize(absolute(outputDir));

    logger.info('Input directory: $inputPath');
    logger.info('Output directory: $outputPath');
    logger.info('Mode: $mode');

    final merger = AndroidLibMerger(
      inputDir: inputPath,
      outputDir: outputPath,
      libName: libName,
      apiLevel: apiLevel,
      excludeLibs: excludeLibs,
      linkLibs: linkLibs,
      strip: strip,
      allowMultipleDefinition: allowMultipleDef,
    );

    if (mode == 'one-to-one') {
      await merger.convertOneToOne();
    } else {
      await merger.convertManyToOne();
    }

    logger.info('Merge completed!');
  }
}

/// Android library merger utility
class AndroidLibMerger with LogMixin {
  final String inputDir;
  final String outputDir;
  final String libName;
  final int apiLevel;
  final List<String> excludeLibs;
  final List<String> linkLibs;
  final bool strip;
  final bool allowMultipleDefinition;

  AndroidLibMerger({
    required this.inputDir,
    required this.outputDir,
    required this.libName,
    required this.apiLevel,
    required this.excludeLibs,
    required this.linkLibs,
    required this.strip,
    required this.allowMultipleDefinition,
  });

  /// Get NDK toolchain path
  String get ndkPath => envs.androidNDK;

  /// Get prebuilt toolchain path
  String get prebuiltPath =>
      join(ndkPath, 'toolchains', 'llvm', 'prebuilt', 'darwin-x86_64');

  /// Get clang path for specific ABI
  String getClangPath(String abi) {
    final triple = _getTriple(abi);
    return join(prebuiltPath, 'bin', '$triple$apiLevel-clang');
  }

  /// Get ar path
  String get arPath => join(prebuiltPath, 'bin', 'llvm-ar');

  /// Get strip path
  String get stripPath => join(prebuiltPath, 'bin', 'llvm-strip');

  /// Convert ABI to NDK triple
  String _getTriple(String abi) {
    switch (abi) {
      case 'arm64-v8a':
        return 'aarch64-linux-android';
      case 'armeabi-v7a':
        return 'armv7a-linux-androideabi';
      case 'x86':
        return 'i686-linux-android';
      case 'x86_64':
        return 'x86_64-linux-android';
      default:
        throw ArgumentError('Unknown ABI: $abi');
    }
  }

  /// Find all ABI directories
  List<String> findAbis() {
    final dir = Directory(inputDir);
    if (!dir.existsSync()) {
      throw StateError('Input directory does not exist: $inputDir');
    }

    final abis = <String>[];
    for (final entity in dir.listSync()) {
      if (entity is Directory) {
        final name = basename(entity.path);
        if (['arm64-v8a', 'armeabi-v7a', 'x86', 'x86_64'].contains(name)) {
          abis.add(name);
        }
      }
    }

    if (abis.isEmpty) {
      throw StateError('No ABI directories found in: $inputDir');
    }

    return abis;
  }

  /// Find all static libraries in a directory
  List<File> findStaticLibs(String abiDir) {
    final libDir = Directory(join(abiDir, 'lib'));
    if (!libDir.existsSync()) {
      return [];
    }

    final libs = <File>[];
    for (final entity in libDir.listSync()) {
      if (entity is File && entity.path.endsWith('.a')) {
        // Skip symlinks to avoid duplicate symbols
        if (FileSystemEntity.isLinkSync(entity.path)) {
          continue;
        }
        final name = basenameWithoutExtension(entity.path);
        // Remove 'lib' prefix for comparison
        final shortName = name.startsWith('lib') ? name.substring(3) : name;
        if (!excludeLibs.contains(shortName)) {
          libs.add(entity);
        }
      }
    }

    return libs;
  }

  /// Convert each static library to shared library (one-to-one)
  Future<void> convertOneToOne() async {
    final abis = findAbis();
    logger.info('Found ABIs: ${abis.join(', ')}');

    for (final abi in abis) {
      final abiInputDir = join(inputDir, abi);
      final abiOutputDir = join(outputDir, abi);

      // Create output directory
      Directory(abiOutputDir).createSync(recursive: true);

      final libs = findStaticLibs(abiInputDir);
      logger.info('[$abi] Found ${libs.length} static libraries');

      for (final lib in libs) {
        final libName = basenameWithoutExtension(lib.path);
        final soName = '$libName.so';
        final soPath = join(abiOutputDir, soName);

        await _convertToShared(abi, [lib.path], soPath);
        logger.info('[$abi] Created: $soName');
      }
    }
  }

  /// Merge all static libraries into single shared library (many-to-one)
  Future<void> convertManyToOne() async {
    final abis = findAbis();
    logger.info('Found ABIs: ${abis.join(', ')}');

    for (final abi in abis) {
      final abiInputDir = join(inputDir, abi);
      final abiOutputDir = join(outputDir, abi);

      // Create output directory
      Directory(abiOutputDir).createSync(recursive: true);

      final libs = findStaticLibs(abiInputDir);
      logger.info('[$abi] Found ${libs.length} static libraries');

      if (libs.isEmpty) {
        logger.warning('[$abi] No static libraries found, skipping');
        continue;
      }

      final soName = 'lib$libName.so';
      final soPath = join(abiOutputDir, soName);

      // Directly link all static libraries into shared library
      // Using --whole-archive to include all symbols
      await _convertToShared(abi, libs.map((f) => f.path).toList(), soPath);

      logger.info('[$abi] Created: $soName');
    }
  }

  /// Merge multiple static libraries into one
  Future<void> _mergeStaticLibs(List<String> inputs, String output) async {
    // Use thin archive for merging
    final args = ['rcsT', output, ...inputs];
    final result = await Process.run(arPath, args);

    if (result.exitCode != 0) {
      throw StateError(
          'Failed to merge static libraries: ${result.stderr}',);
    }
  }

  /// Convert static library to shared library
  Future<void> _convertToShared(
      String abi, List<String> inputs, String output) async {
    final clang = getClangPath(abi);

    final args = <String>[
      '-shared',
      '-o',
      output,
      if (allowMultipleDefinition) '-Wl,--allow-multiple-definition',
      '-Wl,--whole-archive',
      ...inputs,
      '-Wl,--no-whole-archive',
      ...linkLibs.map((l) => '-l$l'),
    ];

    final result = await Process.run(clang, args);

    if (result.exitCode != 0) {
      throw StateError(
          'Failed to create shared library: ${result.stderr}',);
    }

    // Strip if requested
    if (strip) {
      final stripResult = await Process.run(stripPath, [output]);
      if (stripResult.exitCode != 0) {
        logger.warning('Failed to strip: ${stripResult.stderr}');
      }
    }
  }
}
