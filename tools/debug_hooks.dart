import 'dart:io';
import 'package:yaml/yaml.dart';

void main() {
  final content = File('example/libvips/deps/libffi/lib.yaml').readAsStringSync();
  final yaml = loadYaml(content) as Map;
  final hooks = yaml['hooks'] as Map?;
  if (hooks != null) {
    final postConfigure = hooks['post_configure'] as YamlList?;
    if (postConfigure != null) {
      print('Found ${postConfigure.length} post_configure hooks:');
      for (var i = 0; i < postConfigure.length; i++) {
        final item = postConfigure[i];
        print('  Hook $i: ${item.runtimeType}');
        if (item is Map) {
          print('    platform: ${item['platform']}');
          print('    script length: ${(item['script'] as String?)?.length ?? 0}');
        }
      }
    }
  }
}
