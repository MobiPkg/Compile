extension CCStringMapExt on Map<String, String?> {
  Map<String, String?> merge(Map<String, String> other) {
    return {...this, ...other};
  }

  String debugString() {
    return entries.map((e) => e.toEnvString()).join('\n');
  }

  String toEnvString() {
    return entries.map((e) => e.toEnvString()).join(' ');
  }
}

extension CCMapEntryExt on MapEntry<String, String?> {
  String toEnvString() {
    final value = this.value ?? '';
    return '$key="$value"';
  }
}
