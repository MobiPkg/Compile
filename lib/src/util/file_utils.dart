import 'dart:io';

extension StringFileExtensions on String {
  /// Returns the file extension of this path.
  /// If [createWhenNotExists] is true, the directory will be created.
  /// If [createParents] is true, the parent directories will be created.
  File file({
    bool createWhenNotExists = false,
    bool createParents = true,
  }) {
    final file = File(this);
    if (createWhenNotExists) {
      if (createParents) {
        file.createSync(recursive: true);
      } else {
        file.createSync();
      }
    }
    return file;
  }

  /// Returns the directory of this path.
  /// If [createWhenNotExists] is true, the directory will be created.
  /// If [createParents] is true, the parent directories will be created.
  Directory directory({
    bool createWhenNotExists = false,
    bool createParents = true,
  }) {
    final dir = Directory(this);
    if (createWhenNotExists) {
      if (createParents) {
        dir.createSync(recursive: true);
      } else {
        dir.createSync();
      }
    }
    return dir;
  }

  /// Create parent directories if not exists.
  void createParentDirectories() {
    final dir = Directory(this);
    final parent = dir.parent;
    if (!parent.existsSync()) {
      parent.createSync(recursive: true);
    }
  }
}
