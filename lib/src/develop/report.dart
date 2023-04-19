import 'package:compile/compile.dart';

final reporter = CCReport._();
typedef OutputReportFunc = void Function(
  CpuType cpuType,
  CCReportItem reportItem,
);

class CCReport {
  CCReport._() {
    for (final cpuType in [
      ...CpuType.values(),
      IOSCpuType.universal,
    ]) {
      _map[cpuType] = CCReportItem();
    }
  }

  final _map = <CpuType, CCReportItem>{};

  CpuType? _cpuType;

  // ignore: use_setters_to_change_properties
  void changeCpuType(CpuType? cpuType) {
    _cpuType = cpuType;
  }

  void addLog(
    String log, {
    bool newLine = true,
  }) {
    if (_cpuType != null) {
      final item = _map[_cpuType];
      item?.addLog(log);
    } else {
      for (final item in _map.values) {
        item.addLog(log);
      }
    }
  }

  void addCommand({
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

    if (_cpuType != null) {
      final item = _map[_cpuType];
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

  void addLog(
    String log, {
    bool newLine = true,
  }) {
    if (newLine) {
      this.log.writeln(log);
    } else {
      this.log.write(log);
    }
  }

  void addCommand(String command) {
    this.command.writeln(command);
  }
}
