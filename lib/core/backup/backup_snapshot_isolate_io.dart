import 'dart:io';
import 'dart:isolate';

import 'package:drift/native.dart';

import '../database/user_db.dart';
import 'backup_snapshot.dart';

/// Native: reads + encodes pending sessions on a background isolate so a big
/// history never janks the UI.
///
/// The isolate opens its own **read-only-in-practice** connection to the same
/// SQLite file (`query_only`, with a busy timeout so it waits rather than
/// failing if the UI isolate is mid-write). Only [dbPath] and [limit] cross
/// the boundary in; plain data comes back.
Future<BackupSnapshot> buildPendingSnapshotInBackground({
  required String dbPath,
  required int limit,
}) {
  return Isolate.run(() async {
    final db = UserDatabase(
      NativeDatabase(
        File(dbPath),
        setup: (raw) {
          raw.execute('PRAGMA busy_timeout = 5000');
          raw.execute('PRAGMA query_only = ON');
        },
      ),
    );
    try {
      return await buildPendingBackupSnapshot(db, limit: limit);
    } finally {
      await db.close();
    }
  });
}
