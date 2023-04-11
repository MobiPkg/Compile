import 'package:compile/compile.dart';

mixin LibFlagsMixin {
  Map get map;

  Map get flagsMap => map.getMap('flags');

  String get cFlags => flagsMap.stringValue('c');
  String get cppFlags => flagsMap.stringValue('cpp');
  String get cxxFlags => flagsMap.stringValue('cxx');
  String get ldFlags => flagsMap.stringValue('ld');

  void _addFlagsToEnv(Map env, String key, String value) {
    if (value.isNotEmpty) {
      final oldValue = env[key];
      env[key] = oldValue == null ? value : '$oldValue $value';
    }
  }

  void addFlagsToEnv(Map<String, String> env) {
    _addFlagsToEnv(env, 'CFLAGS', cFlags);
    _addFlagsToEnv(env, 'CPPFLAGS', cppFlags);
    _addFlagsToEnv(env, 'CXXFLAGS', cxxFlags);
    _addFlagsToEnv(env, 'LDFLAGS', ldFlags);
  }

  void addFlagsToCmakeArgs(Map<String, String> args) {
    void add(String key, String value) {
      if (value.isNotEmpty) {
        final src = args[key];
        args[key] = src == null ? value : '$src $value';
      }
    }

    add('CMAKE_C_FLAGS_RELEASE', cFlags);
    add('CMAKE_CXX_FLAGS_RELEASE', cxxFlags);
    add('CMAKE_EXE_LINKER_FLAGS_RELEASE', ldFlags);
  }
}
