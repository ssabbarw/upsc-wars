import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/core/backup/backup_snapshot_isolate_io.dart';
import 'package:upsc_wars/core/database/user_db.dart';

/// The one-time backfill reads old users' history on a background isolate that
/// opens its own connection to the on-disk DB.
void main() {
  late Directory dir;
  late File file;
  late UserDatabase db;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('backup_snapshot_test');
    file = File('${dir.path}/test.db');
    db = UserDatabase(NativeDatabase(file));

    Future<void> session(
      String id,
      String status, {
      bool withAttempt = true,
    }) async {
      await db.sessionsDao.insertSession(
        SessionsCompanion.insert(
          id: id,
          createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
          completedAt: Value(
            DateTime.fromMillisecondsSinceEpoch(1700000500000),
          ),
          subject: 'polity',
          mode: 'exam',
          status: status,
          questionCount: 1,
          isTimed: false,
        ),
      );
      if (withAttempt) {
        await db.sessionQuestionsDao.insertBatch([
          SessionQuestionsCompanion.insert(
            id: 'a-$id',
            sessionId: id,
            questionUuid: 'q-$id',
            position: 1,
            selectedOption: const Value('a'),
            status: const Value('wrong'),
          ),
        ]);
      }
    }

    await session('done1', 'completed');
    await session('done2', 'completed');
    await session('empty', 'completed', withAttempt: false);
    await session('midway', 'in_progress');
    await session('already', 'completed');
    await db.sessionsDao.markSessionsBackedUp(['already'], DateTime.now());
  });

  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  test(
    'isolate snapshot returns only completed, not-yet-backed-up sessions',
    () async {
      final snap = await buildPendingSnapshotInBackground(
        dbPath: file.path,
        limit: 100,
      );
      expect(snap.payloads.map((p) => p['sid']).toSet(), {'done1', 'done2'});
      // No attempts -> skipped (marked, never retried).
      expect(snap.skippedIds, ['empty']);
      expect(snap.payloads.first['q'], isA<List>());
    },
  );

  test('respects the batch limit', () async {
    final snap = await buildPendingSnapshotInBackground(
      dbPath: file.path,
      limit: 1,
    );
    expect(snap.payloads.length + snap.skippedIds.length, 1);
  });

  test('isolate connection never writes', () async {
    await buildPendingSnapshotInBackground(dbPath: file.path, limit: 100);
    // Still pending: the snapshot itself must not mark anything.
    final pending = await db.sessionsDao.getSessionsPendingBackup();
    expect(pending.map((s) => s.id).toSet(), {'done1', 'done2', 'empty'});
  });
}
