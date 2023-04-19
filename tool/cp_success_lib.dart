// ignore_for_file: avoid_print

import 'package:compile/compile.dart';
import 'cp_lib.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: cp_success_lib.dart <path>');
    exit(1);
  }

  final srcPath = args[0];
  copyLib(srcPath, 'success');
}
