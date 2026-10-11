import 'dart:io';

const String testDataDir = '../testdata';

/// Lists the `*.yaml` files in [dir] sorted by path for deterministic runs.
List<File> yamlFilesIn(String dir) {
  final directory = Directory(dir);
  final files = directory
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.yaml'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  return files;
}
