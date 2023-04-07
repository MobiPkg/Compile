import 'package:compile/compile.dart';

Future<void> main(List<String> arguments) async {
  final Commander commander = Commander();
  if (arguments.length == 1) {
    arguments = convertArgs(arguments.first);
  }
  await commander.run(arguments);
}

List<String> convertArgs(String arg) {
  arg = arg.trim();
  while (arg.contains('  ')) {
    arg = arg.replaceAll('  ', ' ');
  }
  return arg.split(' ');
}
