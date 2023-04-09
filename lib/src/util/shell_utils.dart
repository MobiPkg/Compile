import 'dart:io';

import 'package:process_run/shell_run.dart' as shell;

bool checkWhich(
  String command, {
  bool throwOnError = true,
  String? throwMessage,
}) {
  final haveCommand = shell.whichSync(command) != null;
  if (!haveCommand && throwOnError) {
    if (throwMessage == null) {
      throwMessage = '';
    } else {
      throwMessage = ': $throwMessage';
    }
    throw Exception('$command not found $throwMessage');
  }
  return haveCommand;
}

void checkEnv(
  String key, {
  String? throwMessage,
}) {
  final env = Platform.environment[key];
  if (env == null || env.isEmpty) {
    if (throwMessage == null) {
      throwMessage = '';
    } else {
      throwMessage = ': $throwMessage';
    }
    throw Exception('Please set $key, $throwMessage');
  }
}
