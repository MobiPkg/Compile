extension StringMapExt on Map<String, String> {
  Map<String, String> merge(Map<String, String> other) {
    return {...this, ...other};
  }

  String debugString() {
    return entries.map((e) => '${e.key}=${e.value}').join('\n');
  }

  String toEnvString() {
    return entries.map((e) => '${e.key}=${e.value}').join(' ');
  }
}
