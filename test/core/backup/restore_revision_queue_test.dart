import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/core/backup/session_backup_codec.dart';
import 'package:upsc_wars/core/backup/session_backup_service.dart';
import 'package:upsc_wars/core/database/user_db.dart';

Map<String, dynamic> _doc(
  String sid,
  String subject,
  int completedMs,
  Map<String, String> statusByUuid,
) => {
  'v': 1,
  'sid': sid,
  'createdAtMs': completedMs - 1000,
  'completedAtMs': completedMs,
  'subject': subject,
  'mode': 'exam',
  'qc': statusByUuid.length,
  'timed': false,
  'lang': 'en',
  'q': [
    for (final e in statusByUuid.entries)
      {
        'u': e.key,
        'st': e.value,
        'c': e.value == 'correct' ? 1 : 0,
        's': 'a',
        'at': completedMs - 500,
      },
  ],
};

void main() {
  late UserDatabase db;
  late SessionBackupService service;

  setUp(() {
    db = UserDatabase(NativeDatabase.memory());
    service = SessionBackupService(userDb: db);
  });

  tearDown(() async => db.close());

  test(
    'replaying history rebuilds queue membership, counts and graduation',
    () async {
      final docs = [
        // t1: q1 and q2 wrong -> both queued.
        _doc('s1', 'polity', 1000000, {
          'q1': 'wrong',
          'q2': 'wrong',
          'q3': 'correct',
        }),
        // t2: revision session, q1 answered correctly -> graduates.
        _doc('s2', 'revision', 2000000, {'q1': 'correct', 'q2': 'wrong'}),
        // t3: q1 wrong again -> back in the queue.
        _doc('s3', 'polity', 3000000, {'q1': 'wrong'}),
      ];
      await service.applyRestoredForTest([
        for (final d in docs) SessionBackupCodec.decode(d)!,
      ]);

      final q1 = (await db.revisionQueueDao.getRevisionQueueItemByQuestionUuid(
        'q1',
      ))!;
      final q2 = (await db.revisionQueueDao.getRevisionQueueItemByQuestionUuid(
        'q2',
      ))!;
      final q3 = await db.revisionQueueDao.getRevisionQueueItemByQuestionUuid(
        'q3',
      );

      // q3 was only ever correct outside revision: never queued.
      expect(q3, isNull);

      // q1: wrong, graduated in revision, wrong again -> active again.
      expect(q1.hasGraduatedFromQueue, isFalse);
      expect(q1.numberOfTimesAnsweredCorrectlyInRevision, 1);
      expect(q1.numberOfTimesAnsweredIncorrectlyInRevision, 2);

      // q2: wrong in s1 and wrong again in the revision session -> still queued.
      expect(q2.hasGraduatedFromQueue, isFalse);
      expect(q2.numberOfTimesAnsweredCorrectlyInRevision, 0);
      expect(q2.numberOfTimesAnsweredIncorrectlyInRevision, 2);
    },
  );

  test('a question that ends on a revision success stays graduated', () async {
    await service.applyRestoredForTest([
      SessionBackupCodec.decode(
        _doc('s1', 'polity', 1000000, {'q1': 'wrong'}),
      )!,
      SessionBackupCodec.decode(
        _doc('s2', 'revision_quick', 2000000, {'q1': 'correct'}),
      )!,
    ]);
    final q1 = (await db.revisionQueueDao.getRevisionQueueItemByQuestionUuid(
      'q1',
    ))!;
    expect(q1.hasGraduatedFromQueue, isTrue);
    expect(q1.dateGraduated, isNotNull);
    expect(await db.revisionQueueDao.fetchActiveQueue(), isEmpty);
  });
}
