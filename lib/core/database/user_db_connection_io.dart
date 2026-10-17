import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<File> _userDbFile() async {
  final docsDir = await getApplicationDocumentsDirectory();
  return File(p.join(docsDir.path, 'upsc_wars_questions.db'));
}

/// Opens the on-device SQLite file (native platforms only).
LazyDatabase openUserDb() {
  return LazyDatabase(() async => NativeDatabase(await _userDbFile()));
}

/// Absolute path of the on-device SQLite file, for background isolates that
/// open their own connection.
Future<String?> userDbFilePath() async => (await _userDbFile()).path;
