import 'dart:io';

extension CCStringExt on String {
  int toInt() {
    return int.parse(this);
  }

  String removeMultipleSpaces() {
    return replaceAll(RegExp(r'\s+'), ' ');
  }

  String removeSuffix(String suffix) {
    if (endsWith(suffix)) {
      return substring(0, length - suffix.length);
    } else {
      return this;
    }
  }
}

extension CCMapExt on Map {
  String stringValue(String key) {
    return this[key] as String? ?? '';
  }

  String? stringValueOrNull(String key) {
    return this[key] as String?;
  }

  Map getMap(String key) {
    return this[key] as Map? ?? {};
  }

  Map? getMapOrNull(String key) {
    return this[key] as Map?;
  }
}

extension CCStringListExt on List<String> {
  String joinWithSpace() {
    return join(' ');
  }
}

extension CCDirectoryExt on Directory {
  void createIfNotExists() {
    if (!existsSync()) {
      createSync(recursive: true);
    }
  }
}
