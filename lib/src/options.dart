final compileOptions = CompileOptions();

class CompileOptions {
  bool verbose = false;

  bool android = true;

  bool ios = true;

  String projectPath = '.';

  bool upload = false;

  bool removeOldSource = false;
}
