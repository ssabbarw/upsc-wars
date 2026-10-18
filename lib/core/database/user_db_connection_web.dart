import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;

/// No file path on web (IndexedDB/OPFS-backed); background isolates unsupported.
Future<String?> userDbFilePath() async => null;

/// Opens Drift via sqlite3 WASM (`web/sqlite3.wasm`, `web/drift_worker.dart.js`).
///
/// Seeds from the same bundled DB asset as [QuestionBankSetup] on native.
LazyDatabase openUserDb() {
  return LazyDatabase(() async {
    return driftDatabase(
      name: 'upsc_wars_questions',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.dart.js'),
        initializeDatabase: () async {
          final data = await rootBundle.load(
            'assets/db/upsc_wars_questions.db',
          );
          return data.buffer.asUint8List();
        },
      ),
    );
  });
}
