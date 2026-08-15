import 'dart:io';

import 'package:hive/hive.dart';

/// Initializes Hive against a fresh temp directory so each test gets
/// isolated, disposable boxes. Call [tearDownHive] with the returned
/// directory after each test.
Directory setUpHive() {
  final dir = Directory.systemTemp.createTempSync('lean_hive_cache_test_');
  Hive.init(dir.path);
  return dir;
}

Future<void> tearDownHive(Directory dir) async {
  await Hive.deleteFromDisk();
  if (dir.existsSync()) {
    dir.deleteSync(recursive: true);
  }
}
