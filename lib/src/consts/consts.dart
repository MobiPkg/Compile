class Consts {
  static const String appName = 'compile';
  static const String ndkKey = 'ANDROID_NDK_HOME';
  static const String hmKey = 'HARMONY_NDK_HOME';
  static const String prefix = 'MOBIPKG_PREFIX';
  static const String gitlabToken = 'GITLAB_TOKEN';

  static const String iOSMutilArchName = 'universal';

  /// Alternative environment variable names for Android SDK
  static const List<String> androidSdkKeys = [
    'ANDROID_SDK_ROOT',
    'ANDROID_HOME',
    'ANDROID_SDK',
  ];
}
