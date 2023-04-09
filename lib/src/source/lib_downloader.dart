import 'package:compile/compile.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart' as shell;

mixin LibDownloadMixin on LibSourceMixin {
  Future<void> downloadGit(String targetPath, GitSource git) async {
    final gitUrl = git.url;
    final ref = git.ref;
    final cmd = 'git clone $gitUrl $targetPath';
    await shell.run(cmd);

    if (ref != null) {
      final cmd = 'git checkout $ref';
      await shell.run(cmd, workingDirectory: targetPath);
    }
  }

  Future<void> copyPath(String targetPath, PathSource source) async {
    final srcPath = source.path;
    final cmd = 'cp -r $srcPath $targetPath';
    await shell.run(cmd);
  }

  Future<void> downloadAndExtractHttp(
    String targetPath,
    HttpSource source,
  ) async {
    final tmpDir = Directory(join(Directory.systemTemp.path, 'download'));
    if (!await tmpDir.exists()) {
      await tmpDir.create(recursive: true);
    }

    final httpUrl = source.url;
    final type = source.typeEnum;

    String cmd;
    final time = DateTime.now().millisecondsSinceEpoch;
    String tmpPath = join(
      tmpDir.absolute.path,
      time.toString(),
    );

    targetPath.directory(createParents: true);

    switch (type) {
      case LibHttpSourceType.zip:
        cmd = 'wget $httpUrl -O $tmpPath';
        await shell.run(cmd);
        cmd = 'unzip $tmpPath -d $targetPath';
        await shell.run(cmd);
        break;
      case LibHttpSourceType.tar:
        cmd = 'wget $httpUrl -O $tmpPath';
        await shell.run(cmd);
        cmd = 'tar -xvf $tmpPath -C $targetPath';
        await shell.run(cmd);
        break;
      case LibHttpSourceType.tarGz:
        cmd = 'wget $httpUrl -O $tmpPath';
        await shell.run(cmd);
        cmd = 'tar -zxvf $tmpPath -C $targetPath';
        await shell.run(cmd);
        break;
      case LibHttpSourceType.tarBz2:
        cmd = 'wget $httpUrl -O $tmpPath';
        await shell.run(cmd);
        cmd = 'tar -jxvf $tmpPath -C $targetPath';
        await shell.run(cmd);
        break;
      case LibHttpSourceType.sevenZ:
        cmd = 'wget $httpUrl -O $tmpPath';
        await shell.run(cmd);
        cmd = '7z x $tmpPath -o$targetPath';
        await shell.run(cmd);
        break;
      default:
        throw Exception('Not support http source type');
    }
  }
}
