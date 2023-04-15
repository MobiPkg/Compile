import 'dart:io';

import 'package:path/path.dart';

void main(List<String> args) {
  const examplesPath = 'example';
  final examplesDir = Directory(examplesPath);

  final examples = examplesDir
      .listSync(recursive: true)
      .whereType<File>()
      .where(
        (element) =>
            basename(element.path) == 'lib.yaml' ||
            basename(element.path) == 'lib.yml',
      )
      .toList()
    ..sort(
      (a, b) => a.parent.absolute.path.compareTo(b.parent.absolute.path),
    );

  final buffer = StringBuffer();

  buffer.writeln(
    '''
# Examples

| dir | lib |
| --- | --- |
'''
        .trim(),
  );

  for (final example in examples) {
    final path = relative(
      example.parent.absolute.path,
      from: examplesDir.parent.absolute.path,
    );

    buffer.writeln(
      '''
| [$path]($path) | [lib.yaml]($path/lib.yaml) |
'''
          .trim(),
    );
  }

  final outFile = File('example-list.md');
  outFile.writeAsStringSync(buffer.toString());
}
