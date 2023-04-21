import 'dart:io';

import 'package:path/path.dart';

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

extension CCDirExt on Directory {
  File? getFirstMatchFile(
    List<String> names, {
    bool matchCase = false,
    bool exactMatch = true,
    bool recursive = false,
  }) {
    bool compare(String listItem, String fileName) {
      if (matchCase) {
        return exactMatch ? listItem == fileName : listItem.contains(fileName);
      } else {
        return exactMatch
            ? listItem.toLowerCase() == fileName.toLowerCase()
            : fileName.toLowerCase().contains(listItem.toLowerCase());
      }
    }

    final dir = this;
    final files = dir.listSync(recursive: recursive);
    for (final file in files) {
      if (file is File) {
        final name = basename(file.path);
        for (final fileName in names) {
          if (compare(name, fileName)) {
            return file;
          }
        }
      }
    }
    return null;
  }

  File childFile(String path) {
    return File(join(this.path, path));
  }
}

extension CCDirListExt on List<Directory> {
  void addPath(String path) {
    add(Directory(path));
  }

  void addJoin(
    String part1, [
    String? part2,
    String? part3,
    String? part4,
    String? part5,
    String? part6,
    String? part7,
    String? part8,
    String? part9,
    String? part10,
    String? part11,
    String? part12,
    String? part13,
    String? part14,
    String? part15,
    String? part16,
  ]) {
    final path = join(
      part1,
      part2,
      part3,
      part4,
      part5,
      part6,
      part7,
      part8,
      part9,
      part10,
      part11,
      part12,
      part13,
      part14,
      part15,
      part16,
    );

    add(Directory(path));
  }
}
