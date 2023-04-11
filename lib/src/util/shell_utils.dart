import 'dart:convert';

import 'package:compile/compile.dart';
import 'package:process_run/shell_run.dart' as sr;

final shell = Shell();

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

class Shell with LogMixin {
  Future<List<ProcessResult>> run(
    String script, {
    bool throwOnError = true,
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool? runInShell,
    Encoding stdoutEncoding = systemEncoding,
    Encoding stderrEncoding = systemEncoding,
    Stream<List<int>>? stdin,
    StreamSink<List<int>>? stdout,
    StreamSink<List<int>>? stderr,
    bool verbose = true,

    // Default to true
    bool? commandVerbose,
    // Default to true if verbose is true
    bool? commentVerbose,
    void Function(Process process)? onProcess,
  }) {
    final log = StringBuffer();
    log.writeLineWithIndent('Running script:');
    log.writeLineWithIndent(script, 2);
    log.writeLineWithIndent('Working directory: $workingDirectory');
    log.writeLineWithIndent('Environment:');
    if (environment != null) {
      log.writeLineWithIndent(environment.debugString(), 2);
    }
    log.writeLineWithIndent(
        'Include parent environment: $includeParentEnvironment');

    logger.d(log.toString().trim());

    return sr.run(
      script,
      commandVerbose: commandVerbose,
      commentVerbose: commentVerbose,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      onProcess: onProcess,
      runInShell: runInShell,
      stderr: stderr,
      stderrEncoding: stderrEncoding,
      stdin: stdin,
      stdout: stdout,
      stdoutEncoding: stdoutEncoding,
      throwOnError: throwOnError,
      verbose: verbose,
      workingDirectory: workingDirectory,
    );
  }

  String? whichSync(
    String command, {
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
  }) {
    return sr.whichSync(
      command,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
    );
  }

  Future<String> exec(String script) async {
    final result = await run(script);
    return result.map((e) => e.stdout).join(' ').trim();
  }
}

extension StringBufferExtForCmd on StringBuffer {
  void writeLineWithIndent(String log, [int indent = 0]) {
    final lines = log.split('\n');
    for (var line in lines) {
      if (line.isNotEmpty) {
        write(' ' * indent);
        write(line);
      }
      writeln();
    }
  }
}
