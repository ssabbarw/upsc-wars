import '../database/user_db.dart';
import 'session_backup_codec.dart';

/// Result of reading pending sessions out of the local DB and encoding them.
///
/// Plain data only (maps, lists, strings) so it can cross an isolate boundary.
class BackupSnapshot {
  const BackupSnapshot({required this.payloads, required this.skippedIds});

  /// Firestore-ready documents (without the server timestamp), one per session.
  final List<Map<String, dynamic>> payloads;

  /// Sessions with nothing worth backing up (no attempts, or too large). They
  /// are marked as backed up so they are not retried forever.
  final List<String> skippedIds;

  bool get isEmpty => payloads.isEmpty && skippedIds.isEmpty;
}

/// Encodes one session, or returns null when it should be skipped.
Future<Map<String, dynamic>?> buildBackupPayload(
  UserDatabase db,
  Session session,
) async {
  final attempts = await db.sessionQuestionsDao.getSessionQuestionsOrdered(
    session.id,
  );
  if (attempts.isEmpty) return null;

  final questions = await db.questionsDao.getByUuidsInOrder([
    for (final a in attempts) a.questionUuid,
  ]);
  final caDates = <String, String>{
    for (final q in questions)
      if (q.sourceDate != null && q.sourceDate!.isNotEmpty)
        q.uuid: q.sourceDate!,
  };
  return SessionBackupCodec.encode(
    session: session,
    attempts: attempts,
    caDates: caDates,
  );
}

/// Reads and encodes up to [limit] completed sessions that are not yet backed
/// up. CPU/IO heavy for big histories, which is why the one-time backfill runs
/// this inside a background isolate.
Future<BackupSnapshot> buildPendingBackupSnapshot(
  UserDatabase db, {
  required int limit,
}) async {
  final pending = (await db.sessionsDao.getSessionsPendingBackup())
      .take(limit)
      .toList();
  final payloads = <Map<String, dynamic>>[];
  final skipped = <String>[];
  for (final s in pending) {
    final payload = await buildBackupPayload(db, s);
    if (payload == null) {
      skipped.add(s.id);
    } else {
      payloads.add(payload);
    }
  }
  return BackupSnapshot(payloads: payloads, skippedIds: skipped);
}
