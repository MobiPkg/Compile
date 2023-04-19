// ignore_for_file: avoid_print

import 'package:compile/compile.dart';
import 'package:path/path.dart';
import 'cp_lib.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: cp_fail_lib.dart <path>');
    exit(1);
  }

  final srcPath = args[0];
  final targetPath = await copyLib(srcPath, 'fail');
  final targetLogPath = join(targetPath, 'logs');

  // copy fail log
  final failReportPath = join('logs', 'report');

  final reportDir = Directory(failReportPath);

  if (!reportDir.existsSync()) {
    print('Fail log path $failReportPath not exists');
    return;
  }

  final dirs = reportDir.listSync().whereType<Directory>().toList();
  if (dirs.isEmpty) {
    print('No fail log found');
    return;
  }

  dirs.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

  // copy latest fail log
  final latestDir = dirs.first;

  print('Check the latest fail log: ${latestDir.path}');
  print('Can you want to copy it to $targetLogPath? (y/n)');
  final input = stdin.readLineSync()?.trim().toLowerCase();

  if (input == 'y' || input == 'yes') {
    var cmd = 'mkdir -p $targetLogPath';
    await shell.run(cmd);
    cmd = 'cp -r ${latestDir.path}/* $targetLogPath';
    print(shell.runSync(cmd));
  }

  print('Done');
}
