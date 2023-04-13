extension CCStringMapExt on Map<String, String?> {
  Map<String, String?> merge(Map<String, String> other) {
    return {...this, ...other};
  }

  String toEnvString({bool export = false, String separator = ' '}) {
    return entries.map((e) => e.toEnvString(export: export)).join(separator);
  }

  String debugString() {
    return toEnvString(separator: '\n');
  }
}

extension CCMapEntryExt on MapEntry<String, String?> {
  String toEnvString({
    bool export = false,
  }) {
    final value = this.value ?? '';
    final kv = '$key="$value"';
    return export ? 'export $kv' : kv;
  }
}
