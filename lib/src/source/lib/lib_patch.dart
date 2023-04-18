import 'package:compile/compile.dart';
import 'package:path/path.dart';

// patch:
//  - path: submodule-url.patch
//    target: .gitmodules
//    workdir: .
//    before-precompile: true

class LibPatch {
  final String path;
  final String target;
  final String workdir;
  final bool beforePrecompile;

  LibPatch({
    required this.path,
    required this.target,
    required this.workdir,
    required this.beforePrecompile,
  });

  factory LibPatch.fromMap(Map map) {
    final path = map['path'] as String;
    final target = map['target'] as String;
    final workdir = map['workdir'] as String? ?? '.';
    final beforePrecompile = map['before-precompile'] as bool? ?? true;
    return LibPatch(
      path: path,
      target: target,
      workdir: workdir,
      beforePrecompile: beforePrecompile,
    );
  }
}

mixin LibPatchMixin {
  Map get map;

  Directory get libDir;

  String get libPath => libDir.absolute.path;

  List<LibPatch> get patches {
    final patches = map['patch'] as List?;
    if (patches == null) {
      return [];
    }
    return patches.map((e) => LibPatch.fromMap(e as Map)).toList();
  }

  List<LibPatch> get beforePrecompilePatches {
    return patches.where((e) => e.beforePrecompile).toList();
  }

  List<LibPatch> get afterPrecompilePatches {
    return patches.where((e) => !e.beforePrecompile).toList();
  }

  void applyLibPath({
    required String sourcePath,
    required bool beforePrecompile,
  }) {
    final patches =
        beforePrecompile ? beforePrecompilePatches : afterPrecompilePatches;

    final logBuffer = StringBuffer('Apply patches:');

    for (final patch in patches) {
      final patchPath = join(libPath, patch.path);
      final targetPath = join(sourcePath, patch.workdir, patch.target);
      final patchCmd = 'patch -p1 -i $patchPath -d $targetPath';
      shell.runSync(patchCmd, workingDirectory: sourcePath);
      logBuffer.writeLineWithIndent(patchCmd, 2);
    }

    if (logBuffer.isNotEmpty) {
      logger.info(logBuffer.toString());
    }
  }
}
