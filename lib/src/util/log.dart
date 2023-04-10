import 'package:compile/compile.dart';
import 'package:logger/logger.dart';

mixin LogMixin {
  late final w = logger.w;
  late final e = logger.e;
  late final i = logger.i;
  late final d = logger.d;
  late final v = logger.v;
  late final wtf = logger.wtf;
  late final log = logger.log;
}

final logger = Logger(
  level: compileOptions.verbose ? Level.verbose : Level.info,
  printer: PrettyPrinter(
    methodCount: 3,
    errorMethodCount: 10,
    printTime: true,
    printEmojis: true,
    // noBoxingByDefault: true,
  ),
  filter: ProductionFilter(),
  // filter: DevelopmentFilter(),
  output: ConsoleOutput(),
);
