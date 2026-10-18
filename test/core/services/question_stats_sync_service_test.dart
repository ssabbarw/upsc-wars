import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/core/database/user_db.dart';
import 'package:upsc_wars/core/domain/entities/answer_confidence.dart';
import 'package:upsc_wars/core/services/question_stats_sync_service.dart';

void main() {
  late UserDatabase db;
  late QuestionStatsSyncService service;

  setUp(() async {
    db = UserDatabase(NativeDatabase.memory());
    service = QuestionStatsSyncService(userDb: db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedQuestion(String uuid) async {
    await db
        .into(db.questions)
        .insert(
          QuestionsCompanion.insert(
            uuid: uuid,
            subject: 'polity',
            topic: 't',
            subTopic: 'st',
            questionType: 'direct',
            correctOption: 'a',
            conceptAnchor: 'c',
            conceptsUsed: '[]',
            enDisplayText: const Value('Stem'),
          ),
        );
  }

  Future<String> seedInProgressSession({
    required String sessionId,
    required String attemptId,
    required String questionUuid,
    required String status,
    String? confidence,
    int? timeSpentSecs,
  }) async {
    await db
        .into(db.sessions)
        .insert(
          SessionsCompanion.insert(
            id: sessionId,
            createdAt: DateTime.utc(2026, 1, 1),
            subject: 'polity',
            mode: 'exam',
            status: 'in_progress',
            questionCount: 1,
            isTimed: false,
          ),
        );
    await db
        .into(db.sessionQuestions)
        .insert(
          SessionQuestionsCompanion.insert(
            id: attemptId,
            sessionId: sessionId,
            questionUuid: questionUuid,
            position: 1,
            selectedOption: const Value('a'),
            isCorrect: Value(status == 'correct'),
            status: Value(status),
            attemptedAt: Value(DateTime.utc(2026, 1, 2)),
            confidence: Value(confidence),
            timeSpentSecs: Value(timeSpentSecs),
          ),
        );
    return sessionId;
  }

  test(
    'persistAttemptsOnSessionComplete writes records and marks unsynced',
    () async {
      await seedQuestion('q1');
      const sessionId = 's1';
      await seedInProgressSession(
        sessionId: sessionId,
        attemptId: 'a1',
        questionUuid: 'q1',
        status: 'correct',
        confidence: AnswerConfidence.verySure,
        timeSpentSecs: 30,
      );
      await db.sessionsDao.updateSessionStatus(sessionId, 'completed');
      await db.sessionsDao.updateSessionCompletedAt(
        sessionId,
        DateTime.utc(2026, 1, 2),
      );

      await service.persistAttemptsOnSessionComplete(sessionId);

      final records = await db.questionAttemptRecordsDao.getBySessionId(
        sessionId,
      );
      expect(records, hasLength(1));
      expect(records.single.questionId, 'q1');
      expect(records.single.isCorrect, isTrue);
      expect(records.single.isSure, isTrue);
      expect(records.single.timeTakenSeconds, 30);
      expect(records.single.skipped, isFalse);

      final session = await db.sessionsDao.getSessionById(sessionId);
      expect(session?.synced, isFalse);
    },
  );

  test('persistAttemptsOnSessionComplete is idempotent', () async {
    await seedQuestion('q1');
    const sessionId = 's2';
    await seedInProgressSession(
      sessionId: sessionId,
      attemptId: 'a1',
      questionUuid: 'q1',
      status: 'wrong',
    );
    await db.sessionsDao.updateSessionStatus(sessionId, 'completed');
    await db.sessionsDao.updateSessionCompletedAt(
      sessionId,
      DateTime.utc(2026, 1, 2),
    );

    await service.persistAttemptsOnSessionComplete(sessionId);
    await service.persistAttemptsOnSessionComplete(sessionId);

    final records = await db.questionAttemptRecordsDao.getBySessionId(
      sessionId,
    );
    expect(records, hasLength(1));
  });

  test(
    'only UUID-shaped question ids are synced (matches firestore.rules)',
    () {
      expect(
        QuestionStatsSyncService.isSyncableQuestionId(
          '6148ef93-2c7b-4e62-8dee-18384b13e3f5',
        ),
        isTrue,
      );
      // Malformed ids that ship in the bundled bank.
      expect(
        QuestionStatsSyncService.isSyncableQuestionId(
          'e5f6a7b8-c9d0-4e1f-2a3b-4c5d6e7f8g9h',
        ),
        isFalse,
      );
      expect(QuestionStatsSyncService.isSyncableQuestionId('qu1'), isFalse);
    },
  );
}
