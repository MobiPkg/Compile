import 'package:args/command_runner.dart';
import 'package:compile/compile.dart';

class SupportCommand extends BaseListCommand {
  @override
  String get commandDescription => 'Show support informations';

  @override
  String get name => 'support';

  @override
  List<Command<void>> get subCommands => [
        _SupportType(),
      ];
}

mixin _SupportInfoMixin<T extends ConfigType> on LogMixin {
  void showInfo(String title, List<T> values) {
    final buffer = StringBuffer();
    buffer.writeln('Support $title:');
    for (final element in values) {
      buffer.writeln('  ${element.value}');
    }
    logger.i(buffer.toString().trim());
  }
}

class _SupportType extends BaseVoidCommand with _SupportInfoMixin<LibType> {
  @override
  String get commandDescription => 'Show support types';

  @override
  String get name => 'type';

  @override
  FutureOr<void>? runCommand() {
    showInfo('type', LibType.values);
  }
}
