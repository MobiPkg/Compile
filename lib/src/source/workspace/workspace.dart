import 'package:compile/compile.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

/// Workspace 中的库引用
class WorkspaceLibRef {
  final String name;
  final String path;

  WorkspaceLibRef({
    required this.name,
    required this.path,
  });

  factory WorkspaceLibRef.fromMap(Map map) {
    final name = map['name'] as String?;
    final path = map['path'] as String?;

    if (name == null || name.isEmpty) {
      throw Exception('Workspace lib must have a name');
    }
    if (path == null || path.isEmpty) {
      throw Exception('Workspace lib must have a path');
    }

    return WorkspaceLibRef(name: name, path: path);
  }
}

/// Workspace 配置
/// 
/// workspace.yaml 格式:
/// ```yaml
/// name: my-workspace
/// libs:
///   - name: zlib
///     path: deps/zlib
///   - name: glib
///     path: deps/glib
///   - name: libvips
///     path: libvips
/// ```
class Workspace with LogMixin {
  final String name;
  final Directory workspaceDir;
  final List<WorkspaceLibRef> libRefs;

  /// 缓存已加载的 Lib 对象
  final Map<String, Lib> _libCache = {};

  Workspace._({
    required this.name,
    required this.workspaceDir,
    required this.libRefs,
  });

  /// 从目录加载 Workspace
  factory Workspace.fromDir(Directory dir) {
    if (!dir.existsSync()) {
      throw Exception('Workspace directory not exists: ${dir.path}');
    }

    final matchFiles = ['workspace.yaml', 'workspace.yml'];
    File? configFile;

    for (final fileName in matchFiles) {
      final file = File(join(dir.path, fileName));
      if (file.existsSync()) {
        configFile = file;
        break;
      }
    }

    if (configFile == null) {
      throw Exception(
        'Not found workspace config file in ${dir.path}. '
        'Expected: ${matchFiles.join(' or ')}',
      );
    }

    final yaml = loadYaml(configFile.readAsStringSync()) as Map;
    final name = yaml['name'] as String? ?? basename(dir.path);

    final libsList = yaml['libs'] as YamlList?;
    if (libsList == null || libsList.isEmpty) {
      throw Exception('Workspace must have at least one lib');
    }

    final libRefs = libsList
        .whereType<Map>()
        .map((e) => WorkspaceLibRef.fromMap(e))
        .toList();

    // 检查名称唯一性
    final names = <String>{};
    for (final ref in libRefs) {
      if (names.contains(ref.name)) {
        throw Exception('Duplicate lib name in workspace: ${ref.name}');
      }
      names.add(ref.name);
    }

    return Workspace._(
      name: name,
      workspaceDir: dir,
      libRefs: libRefs,
    );
  }

  /// 从路径加载 Workspace
  factory Workspace.fromPath(String path) {
    return Workspace.fromDir(Directory(path));
  }

  /// 获取库的目录路径
  String getLibPath(String name) {
    final ref = libRefs.firstWhere(
      (e) => e.name == name,
      orElse: () => throw Exception('Lib not found in workspace: $name'),
    );
    return normalize(join(workspaceDir.path, ref.path));
  }

  /// 加载指定名称的库
  Lib getLib(String name) {
    if (_libCache.containsKey(name)) {
      return _libCache[name]!;
    }

    final libPath = getLibPath(name);
    final libDir = Directory(libPath);
    if (!libDir.existsSync()) {
      throw Exception('Lib directory not exists: $libPath');
    }

    final lib = Lib.fromDir(libDir);
    _libCache[name] = lib;
    return lib;
  }

  /// 获取所有库名称
  List<String> get libNames => libRefs.map((e) => e.name).toList();

  /// 检查库是否存在
  bool hasLib(String name) => libRefs.any((e) => e.name == name);

  /// 解析库的依赖并返回拓扑排序后的编译顺序
  /// 
  /// [targetLib] 目标库名称，如果为 null 则编译所有库
  /// 返回按依赖顺序排列的库列表
  List<Lib> resolveDependencies({String? targetLib}) {
    // 构建依赖图
    final graph = <String, Set<String>>{};
    final visited = <String>{};
    final result = <String>[];

    // 递归收集依赖
    void collectDeps(String name) {
      if (visited.contains(name)) return;
      visited.add(name);

      if (!hasLib(name)) {
        logger.w('Dependency not found in workspace: $name (skipped)');
        return;
      }

      final lib = getLib(name);
      final deps = lib.deps;
      graph[name] = deps.toSet();

      for (final dep in deps) {
        collectDeps(dep);
      }
    }

    // 收集需要编译的库
    if (targetLib != null) {
      collectDeps(targetLib);
    } else {
      for (final name in libNames) {
        collectDeps(name);
      }
    }

    // 拓扑排序 (Kahn's algorithm)
    final inDegree = <String, int>{};
    for (final name in graph.keys) {
      inDegree[name] = 0;
    }
    for (final deps in graph.values) {
      for (final dep in deps) {
        if (inDegree.containsKey(dep)) {
          inDegree[dep] = (inDegree[dep] ?? 0) + 1;
        }
      }
    }

    // 找出入度为 0 的节点
    final queue = <String>[];
    for (final entry in inDegree.entries) {
      if (entry.value == 0) {
        queue.add(entry.key);
      }
    }

    while (queue.isNotEmpty) {
      final node = queue.removeAt(0);
      result.add(node);

      for (final dep in graph[node] ?? <String>{}) {
        if (inDegree.containsKey(dep)) {
          inDegree[dep] = inDegree[dep]! - 1;
          if (inDegree[dep] == 0) {
            queue.add(dep);
          }
        }
      }
    }

    // 检查循环依赖
    if (result.length != graph.length) {
      final remaining = graph.keys.where((e) => !result.contains(e)).toList();
      throw Exception('Circular dependency detected: $remaining');
    }

    // 反转顺序，因为我们需要先编译依赖
    return result.reversed.map((name) => getLib(name)).toList();
  }
}
