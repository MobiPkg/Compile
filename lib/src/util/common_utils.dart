extension CCStringExt on String {
  int toInt() {
    return int.parse(this);
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
