import 'package:compile/compile.dart';
import 'package:path/path.dart';

mixin LibDownloadMixin on LibSourceMixin, LogMixin {
  Future<void> downloadGit(String targetPath, GitSource git) async {
    final depth = compileOptions.gitDepth;

    final gitUrl = git.url;
    final ref = git.ref;
    var cmd = 'git clone $gitUrl $targetPath --depth $depth';
    if (ref != null) {
      cmd = '$cmd --branch $ref';
    }
    await shell.run(cmd);
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
    final tmpPath = join(
      tmpDir.absolute.path,
      time.toString(),
    );

    targetPath.directory(createWhenNotExists: true);
    i('Download and extract http source to $targetPath');
    cmd = 'wget $httpUrl -O $tmpPath';
    await shell.run(cmd);

    switch (type) {
      case LibHttpSourceType.zip:
        cmd = 'unzip $tmpPath -d $targetPath';
        await shell.run(cmd);
        break;
      case LibHttpSourceType.tar:
        cmd = 'tar -xvf $tmpPath -C $targetPath';
        await shell.run(cmd);
        break;
      case LibHttpSourceType.tarGz:
        cmd = 'tar -zxvf $tmpPath -C $targetPath';
        await shell.run(cmd);
        break;
      case LibHttpSourceType.tarBz2:
        cmd = 'tar -jxvf $tmpPath -C $targetPath';
        await shell.run(cmd);
        break;
      case LibHttpSourceType.sevenZ:
        cmd = '7z x $tmpPath -o$targetPath';
        await shell.run(cmd);
        break;
      case LibHttpSourceType.tarXz:
        cmd = 'tar -Jxvf $tmpPath -C $targetPath';
        await shell.run(cmd);
        break;
      case LibHttpSourceType.xz:
        cmd = 'xz -d $tmpPath -C $targetPath';
        await shell.run(cmd);
        break;
      case LibHttpSourceType.lzma:
        cmd = 'lzma -d $tmpPath -C $targetPath';
        await shell.run(cmd);
        break;
      case LibHttpSourceType.tarLzma:
        cmd = 'tar --lzma -xvf $tmpPath -C $targetPath';
        await shell.run(cmd);
        break;
    }
  }
}
