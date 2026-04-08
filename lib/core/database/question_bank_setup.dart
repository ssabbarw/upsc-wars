import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/prefs_provider.dart';

/// Copies the asset question bank into documents once, then marks prefs.
class QuestionBankSetup {
  QuestionBankSetup._();

  static const _assetDbPath = 'assets/db/upsc_wars_questions.db';
  static const _fileName = 'upsc_wars_questions.db';

  /// Ensures the SQLite file exists under app documents and [PrefKeys.dbInitialized] is set.
  static Future<void> ensureReady(SharedPreferences prefs) async {
    final dir = await getApplicationDocumentsDirectory();
    final target = File(p.join(dir.path, _fileName));
    if (!await target.exists()) {
      final data = await rootBundle.load(_assetDbPath);
      final bytes = data.buffer.asUint8List();
      await target.writeAsBytes(bytes, flush: true);
    }
    await prefs.setBool(PrefKeys.dbInitialized, true);
  }
}
