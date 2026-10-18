import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/core/database/user_db.dart';
import 'package:upsc_wars/core/domain/entities/answer_confidence.dart';

void main() {
  late UserDatabase db;

  setUp(() async {
    db = UserDatabase(NativeDatabase.memory());
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

  Future<void> seedCompletedAttempt({
    required String sessionId,
    required String attemptId,
    required String questionUuid,
    required String status,
    String? confidence,
  }) async {
    await db
        .into(db.sessions)
        .insert(
          SessionsCompanion.insert(
            id: sessionId,
            createdAt: DateTime.utc(2026, 1, 1),
            completedAt: Value(DateTime.utc(2026, 1, 2)),
            subject: 'polity',
            mode: 'exam',
            status: 'completed',
            questionCount: 1,
            isTimed: false,
          ),
          mode: InsertMode.insertOrReplace,
        );
    await db
        .into(db.sessionQuestions)
        .insert(
          SessionQuestionsCompanion.insert(
            id: attemptId,
            sessionId: sessionId,
            questionUuid: questionUuid,
            position: 1,
            selectedOption: const Value('b'),
            isCorrect: Value(status == 'correct'),
            status: Value(status),
            attemptedAt: Value(DateTime.utc(2026, 1, 2)),
            confidence: Value(confidence),
          ),
        );
  }

  test(
    'hasSureOrEducatedOnCompletedSessions is true for sure/educated rows',
    () async {
      await seedQuestion('q1');
      await seedCompletedAttempt(
        sessionId: 's1',
        attemptId: 'a1',
        questionUuid: 'q1',
        status: 'wrong',
        confidence: AnswerConfidence.somewhatSure,
      );

      expect(
        await db.sessionQuestionsDao.hasSureOrEducatedOnCompletedSessions(),
        isTrue,
      );
    },
  );

  test(
    'hasSureOrEducatedOnCompletedSessions is false for guessing only',
    () async {
      await seedQuestion('q1');
      await seedCompletedAttempt(
        sessionId: 's1',
        attemptId: 'a1',
        questionUuid: 'q1',
        status: 'wrong',
        confidence: AnswerConfidence.guessing,
      );

      expect(
        await db.sessionQuestionsDao.hasSureOrEducatedOnCompletedSessions(),
        isFalse,
      );
    },
  );
}
