// ignore_for_file: avoid_print

import 'package:compile/compile.dart';
import 'package:path/path.dart';

Future<String> copyLib(String srcPath, String prefix) async {
  final srcDir = Directory(srcPath);

  if (!srcDir.existsSync()) {
    print('Path $srcPath not exists');
    exit(2);
  }

  bool isLib = false;

  File? libFile;

  final files = srcDir.listSync(recursive: true);
  for (final file in files) {
    if (file is! File) continue;
    final name = basename(file.path);
    if (name == 'lib.yaml' || name == 'lib.yml') {
      isLib = true;
      libFile = file;
      break;
    }
  }

  if (!isLib || libFile == null) {
    print('Path $srcPath is not a lib, no lib.yaml or lib.yml found');
    exit(3);
  }

  final basePath = 'example-libs/$prefix-libs';

  if (!basePath.directory().existsSync()) {
    print('Base path $basePath not exists');
    exit(4);
  }

  final targetBaseName = basename(srcPath);

  final sub2Name = targetBaseName.substring(0, 2);

  var targetPath = join(basePath, sub2Name, targetBaseName);

  if (targetPath.directory().existsSync()) {
    print('Target path $targetPath already exists');
    exit(5);
  }

  // Get git ref
  final lib = Lib.fromDir(srcDir);
  targetPath = getTargetPath(lib, srcPath, targetPath);

  final targetDir = targetPath.directory();

  if (targetDir.existsSync()) {
    print('Target path $targetPath already exists');
    exit(8);
  } else {
    targetDir.createIfNotExists();
  }

  // copy lib.yaml content to target path
  var cmd = 'cp -r ${libFile.absolute.path} $targetPath';
  await shell.run(cmd);

  final ignoreFile = File(join(srcPath, '.gitignore'));

  if (ignoreFile.existsSync()) {
    cmd = 'cp -r ${ignoreFile.absolute.path} $targetPath';
    await shell.run(cmd);
  }

  return targetPath;
}

String getTargetPath(Lib lib, String srcPath, String targetPath) {
  if (lib.sourceType == LibSourceType.git) {
    final ref = lib.gitSource.ref;

    if (ref == null) {
      print('Lib $srcPath has no ref, please add ref to lib.yaml');
      exit(7);
    }

    // copy lib to target path
    return join(targetPath, ref);
  } else if (lib.sourceType == LibSourceType.http) {
    final httpSource = lib.httpSource;
    return join(targetPath, httpSource.version);
  } else {
    print('Lib $srcPath is not a git lib');
    exit(6);
  }
}
