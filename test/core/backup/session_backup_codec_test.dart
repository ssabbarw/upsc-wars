import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/core/backup/session_backup_codec.dart';
import 'package:upsc_wars/core/database/user_db.dart';

/// One backup doc per attempt must survive an encode -> decode -> insert round
/// trip without losing anything the series dashboard / review screens read.
void main() {
  late UserDatabase source;
  late UserDatabase target;

  setUp(() async {
    source = UserDatabase(NativeDatabase.memory());
    target = UserDatabase(NativeDatabase.memory());

    await source.sessionsDao.insertSession(
      SessionsCompanion.insert(
        id: 's1',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        completedAt: Value(DateTime.fromMillisecondsSinceEpoch(1700000600000)),
        subject: 'test_series',
        topic: const Value('static_polity_01'),
        mode: 'exam',
        status: 'completed',
        questionCount: 3,
        isTimed: true,
        timeLimitSecs: const Value(3600),
        language: const Value('hi'),
        analyticsFeatureKey: const Value('test_series'),
        seriesId: const Value('prelims_2027'),
        seriesTestId: const Value('static_polity_01'),
      ),
    );
    await source.sessionQuestionsDao.insertBatch([
      SessionQuestionsCompanion.insert(
        id: 'a1',
        sessionId: 's1',
        questionUuid: 'q1',
        position: 1,
        selectedOption: const Value('b'),
        isCorrect: const Value(true),
        status: const Value('correct'),
        timeSpentSecs: const Value(41),
        attemptedAt: Value(DateTime.fromMillisecondsSinceEpoch(1700000100000)),
        confidence: const Value('very_sure'),
      ),
      SessionQuestionsCompanion.insert(
        id: 'a2',
        sessionId: 's1',
        questionUuid: 'q2',
        position: 2,
        selectedOption: const Value('c'),
        isCorrect: const Value(false),
        status: const Value('wrong'),
        timeSpentSecs: const Value(12),
        flagged: const Value(true),
        confidence: const Value('guessing'),
      ),
      SessionQuestionsCompanion.insert(
        id: 'a3',
        sessionId: 's1',
        questionUuid: 'q3',
        position: 3,
      ),
    ]);
  });

  tearDown(() async {
    await source.close();
    await target.close();
  });

  test('encode -> decode -> insert preserves the attempt', () async {
    final session = (await source.sessionsDao.getSessionById('s1'))!;
    final attempts = await source.sessionQuestionsDao
        .getSessionQuestionsOrdered('s1');

    final payload = SessionBackupCodec.encode(
      session: session,
      attempts: attempts,
      caDates: const {'q3': '2026-05-04'},
    )!;
    final restored = SessionBackupCodec.decode(payload)!;

    expect(restored.id, 's1');
    expect(restored.caDatesByUuid, {'q3': '2026-05-04'});

    await target.sessionsDao.insertSession(restored.session);
    await target.sessionQuestionsDao.insertBatch(restored.attempts);

    final s = (await target.sessionsDao.getSessionById('s1'))!;
    expect(s.status, 'completed');
    expect(s.seriesId, 'prelims_2027');
    expect(s.seriesTestId, 'static_polity_01');
    expect(s.timeLimitSecs, 3600);
    expect(s.language, 'hi');
    expect(s.completedAt, session.completedAt);
    // Restored sessions must never be re-aggregated into global stats or
    // re-uploaded.
    expect(s.synced, isTrue);
    expect(s.backedUpAt, isNotNull);

    final rows = await target.sessionQuestionsDao.getSessionQuestionsOrdered(
      's1',
    );
    expect(rows.map((r) => r.questionUuid), ['q1', 'q2', 'q3']);
    expect(rows[0].selectedOption, 'b');
    expect(rows[0].isCorrect, isTrue);
    expect(rows[0].status, 'correct');
    expect(rows[0].timeSpentSecs, 41);
    expect(rows[0].confidence, 'very_sure');
    expect(rows[1].isCorrect, isFalse);
    expect(rows[1].flagged, isTrue);
    expect(rows[2].status, 'unattempted');
    expect(rows[2].selectedOption, isNull);
    expect(rows[2].isCorrect, isNull);
  });

  test('decode rejects malformed or future-schema docs', () {
    expect(SessionBackupCodec.decode({}), isNull);
    expect(SessionBackupCodec.decode({'v': 99, 'sid': 'x', 'q': []}), isNull);
  });

  test('pending backup query only returns completed, unbacked sessions', () async {
    expect(
      (await source.sessionsDao.getSessionsPendingBackup()).map((s) => s.id),
      ['s1'],
    );
    await source.sessionsDao.markSessionsBackedUp(['s1'], DateTime.now());
    expect(await source.sessionsDao.getSessionsPendingBackup(), isEmpty);
    expect(await source.sessionsDao.existingSessionIds(['s1', 'nope']), {'s1'});
  });
}
