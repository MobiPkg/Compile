import 'package:compile/compile.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart' as shell;

class AutoToolsCommand extends BaseVoidCommand with CompilerCommandMixin {
  @override
  String get commandDescription => 'AutoTools compile';

  @override
  String get name => 'autotools';

  @override
  List<String> get aliases => ['at', 'a'];

  @override
  Future<FutureOr<void>> doCompileAndroid(
    Lib lib,
    Map<String, String> env,
    String prefix,
  ) async {
    await _compile(lib, env, prefix);
  }

  @override
  FutureOr<void> doCompileIOS(
    Lib lib,
    Map<String, String> env,
    String prefix,
  ) async {
    await _compile(lib, env, prefix);
  }

  Future<void> _compile(
    Lib lib,
    Map<String, String> env,
    String prefix,
  ) async {
    final sourceDir = lib.sourcePath;
    // check configure exists
    if (!File(join(sourceDir, 'configure')).existsSync()) {
      print('configure not found');
      await shell.run('autoreconf -i -v', workingDirectory: sourceDir);
    }

    // check configure exists
    if (!File(join(sourceDir, 'configure')).existsSync()) {
      print('configure not found');
      return;
    }

    final host = env['HOST'];
    if (host == null) {
      print('HOST not found');
      return;
    }

    // configure
    await shell.run(
      './configure --prefix=$prefix --host $host',
      workingDirectory: sourceDir,
      environment: env,
    );

    // make
    final cpuNumber =
        int.parse((await shell.run('sysctl -n hw.ncpu')).outLines.first);

    await shell.run(
      'make -j$cpuNumber',
      workingDirectory: sourceDir,
      environment: env,
    );

    // make install
    await shell.run(
      'make install',
      workingDirectory: sourceDir,
      environment: env,
    );
  }
}