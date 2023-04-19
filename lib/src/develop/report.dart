import 'package:compile/compile.dart';

final reporter = CCReport._();
typedef OutputReportFunc = void Function(
  CpuType cpuType,
  CCReportItem reportItem,
);

class CCReport {
  CCReport._() {
    for (final cpuType in CpuType.values()) {
      _map[cpuType] = CCReportItem();
    }
  }

  final _map = <CpuType, CCReportItem>{};

  void addLog(CpuType? cpuType, String log) {
    if (cpuType != null) {
      final item = _map[cpuType];
      item?.addLog(log);
    } else {
      for (final item in _map.values) {
        item.addLog(log);
      }
    }
  }

  void addCommand({
    required CpuType? cpuType,
    required String command,
    required String? workDir,
    required Map<String, String>? env,
  }) {
    void addInfo(CCReportItem target) {
      // write env
      if (env != null) {
        for (final envEntry in env.entries) {
          target.addCommand('${envEntry.key}="${envEntry.value}"');
        }
      }

      // write work dir
      if (workDir != null) {
        target.addCommand('cd $workDir');
      }

      // write command
      target.addCommand(command);
    }

    if (cpuType != null) {
      final item = _map[cpuType];
      if (item == null) {
        return;
      }
      addInfo(item);
    } else {
      for (final item in _map.values) {
        addInfo(item);
      }
    }
  }

  void output(OutputReportFunc func) {
    for (final entry in _map.entries) {
      func(entry.key, entry.value);
    }
  }
}

class CCReportItem {
  final StringBuffer log = StringBuffer();
  final StringBuffer command = StringBuffer();

  void addLog(String log) {
    this.log.writeln(log);
  }

  void addCommand(String command) {
    this.command.writeln(command);
  }
}
