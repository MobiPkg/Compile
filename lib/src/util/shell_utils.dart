import 'dart:convert';

import 'package:compile/compile.dart';
import 'package:process_run/shell_run.dart' as sr;

final shell = Shell();

bool checkWhich(
  String command, {
  bool throwOnError = true,
  String? throwMessage,
}) {
  String message;
  final haveCommand = shell.whichSync(command) != null;
  if (!haveCommand && throwOnError) {
    if (throwMessage == null) {
      message = '';
    } else {
      message = ': $throwMessage';
    }
    throw Exception('$command not found $message');
  }
  return haveCommand;
}

void checkEnv(
  String key, {
  String? throwMessage,
}) {
  String message;
  final env = Platform.environment[key];
  if (env == null || env.isEmpty) {
    if (throwMessage == null) {
      message = '';
    } else {
      message = ': $throwMessage';
    }
    throw Exception('Please set $key, $message');
  }
}

final _reportSink = StreamController<List<int>>.broadcast();

Stream<List<int>> get reportStream => _reportSink.stream;

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
    bool verbose = true,

    // Default to true
    bool? commandVerbose,
    // Default to true if verbose is true
    bool? commentVerbose,
    void Function(Process process)? onProcess,
  }) async {
    final log = StringBuffer();
    log.writeLineWithIndent('Running script:');
    log.writeLineWithIndent(script, 2);
    log.writeLineWithIndent('Working directory: $workingDirectory');
    log.writeLineWithIndent('Environment:');
    if (environment != null) {
      log.writeLineWithIndent(environment.debugString(), 2);
    }
    log.writeLineWithIndent(
      'Include parent environment: $includeParentEnvironment',
    );

    logger.d(log.toString().trim());

    reporter.addCommand(
      command: script,
      workDir: workingDirectory ?? Directory.current.absolute.path,
      env: environment,
    );

    final sub = reportStream.listen((event) {
      reporter.addLog(systemEncoding.decode(event), newLine: false);
      stdout.add(event);
    });

    try {
      final result = await sr.run(
        'sh -C "$script"',
        commandVerbose: commandVerbose,
        commentVerbose: commentVerbose,
        environment: environment,
        includeParentEnvironment: includeParentEnvironment,
        onProcess: onProcess,
        runInShell: runInShell,
        stderr: _reportSink,
        stderrEncoding: stderrEncoding,
        stdin: stdin,
        stdout: _reportSink,
        stdoutEncoding: stdoutEncoding,
        throwOnError: throwOnError,
        verbose: verbose,
        workingDirectory: workingDirectory,
      );

      return result;
    } catch (e, st) {
      final log = StringBuffer();
      final env = environment ?? {};
      log.writeln('env:');
      log.writeLineWithIndent(env.debugString(), 2);
      log.writeln('workingDirectory: $workingDirectory');
      log.writeln('script:');
      log.writeLineWithIndent(script, 2);
      simpleLogger.error(log.toString().trim());
      return Future.error(e, st);
    } finally {
      sub.cancel();
    }
  }

  String runSync(
    String script, {
    bool throwOnError = true,
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool? runInShell,
    Encoding stdoutEncoding = systemEncoding,
    Encoding stderrEncoding = systemEncoding,
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
      'Include parent environment: $includeParentEnvironment',
    );

    reporter.addCommand(
      command: script,
      workDir: workingDirectory ?? Directory.current.absolute.path,
      env: environment,
    );

    logger.d(log.toString().trim());
    final r = Process.runSync(
      'sh',
      ['-c', script],
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell ?? false,
      stderrEncoding: stderrEncoding,
      stdoutEncoding: stdoutEncoding,
      workingDirectory: workingDirectory,
    );

    final output = r.stdout as String?;
    if (output != null) {
      reporter.addLog(output);
    }

    if (r.exitCode != 0) {
      final errorLog = r.stderr as String?;
      if (errorLog != null) {
        reporter.addLog(errorLog);
      }
      if (throwOnError) {
        throw Exception(r.stderr);
      } else {
        logger.e(r.stderr);
      }
    }
    return r.stdout as String;
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

  void chmod(String shellPath, String permssion) {
    runSync('chmod $permssion $shellPath');
  }
}

extension StringBufferExtForCmd on StringBuffer {
  void writeLineWithIndent(String log, [int indent = 0]) {
    final lines = log.split('\n');
    for (final line in lines) {
      if (line.isNotEmpty) {
        write(' ' * indent);
        write(line);
      }
      writeln();
    }
  }
}

extension StringExtForCmd on String {
  String formatCommand([List<Pattern> needNewLinePrefix = const []]) {
    final src = trim().removeMultipleSpaces();

    logger.info('src command: $src');

    final buffer = StringBuffer();
    final params = src.split(' ');

    for (var i = 0; i < params.length; i++) {
      final param = params[i];
      if (needNewLinePrefix.any((element) => param.startsWith(element))) {
        buffer.writeln(' \\');
        buffer.write(' ' * 4);
      } else {
        buffer.write(' ');
      }
      buffer.write(param);
    }

    logger.info('formatCommand: $buffer');

    return buffer.toString().trim();
  }

  String formatCommandDefault() {
    return formatCommand([RegExp('--')]);
  }
}
