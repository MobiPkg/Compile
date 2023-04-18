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
  final LibPatchType type;

  LibPatch({
    required this.path,
    required this.target,
    required this.workdir,
    required this.beforePrecompile,
    required this.type,
  });

  factory LibPatch.fromMap(Map map) {
    final path = map['path'] as String;
    final target = map['target'] as String;
    final workdir = map['workdir'] as String? ?? '.';
    final beforePrecompile = map['before-precompile'] as bool? ?? true;
    final type = map['type'] as String? ?? 'unified';
    return LibPatch(
      path: path,
      target: target,
      workdir: workdir,
      beforePrecompile: beforePrecompile,
      type: LibPatchType.fromString(type),
    );
  }
}

enum LibPatchType {
  normal,
  context,
  unified;

  static LibPatchType fromString(String value) {
    switch (value) {
      case 'normal':
        return LibPatchType.normal;
      case 'context':
        return LibPatchType.context;
      case 'unified':
        return LibPatchType.unified;
      default:
        throw ArgumentError('Invalid patch type: $value');
    }
  }

  String getPatchOption() {
    switch (this) {
      case LibPatchType.normal:
        return '-n';
      case LibPatchType.context:
        return '-c';
      case LibPatchType.unified:
        return '-u';
    }
  }

  String getDiffOption([int numLines = 3]) {
    switch (this) {
      case LibPatchType.normal:
        return '--normal';
      case LibPatchType.context:
        return '-C $numLines';
      case LibPatchType.unified:
        return '-U $numLines';
    }
  }
}

mixin LibPatchMixin {
  Map get map;

  Directory get libDir;

  String get libPath => libDir.absolute.path;

  String get sourcePath;

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
    required bool beforePrecompile,
  }) {
    final patches =
        beforePrecompile ? beforePrecompilePatches : afterPrecompilePatches;

    final logBuffer = StringBuffer('Apply patches:');

    for (final patch in patches) {
      final patchPath = join(libPath, patch.path);
      final targetPath = join(sourcePath, patch.workdir, patch.target);

      final patchOption = patch.type.getPatchOption();

      final patchCmd = 'patch -i $patchPath $patchOption -N $targetPath';
      shell.runSync(patchCmd, workingDirectory: sourcePath);
      logBuffer.writeLineWithIndent(patchCmd, 2);
    }

    if (logBuffer.isNotEmpty) {
      logger.info(logBuffer.toString());
    }
  }
}
