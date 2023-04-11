import 'package:compile/compile.dart';

Future<void> main(List<String> args) async {
  List<String> arguments = args;
  final Commander commander = Commander();
  if (args.length == 1) {
    arguments = convertArgs(args.first);
  }
  await commander.run(arguments);
}

List<String> convertArgs(String argText) {
  var arg = argText.trim();
  while (arg.contains('  ')) {
    arg = arg.replaceAll('  ', ' ');
  }
  return arg.split(' ');
}
