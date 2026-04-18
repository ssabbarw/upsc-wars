import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/core/database/user_db.dart';
import 'package:upsc_wars/core/domain/entities/answer_confidence.dart';
import 'package:upsc_wars/features/history/data/repositories/session_history_repository_impl.dart';

void main() {
  late UserDatabase db;

  setUp(() async {
    db = UserDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedQuestion(String uuid, {String subject = 's'}) async {
    await db.into(db.questions).insert(
          QuestionsCompanion.insert(
            uuid: uuid,
            subject: subject,
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

  Future<void> seedSessionWithAttempts(
    String sessionId, {
    required List<SessionQuestionsCompanion> attemptRows,
  }) async {
    await db.into(db.sessions).insert(
          SessionsCompanion.insert(
            id: sessionId,
            createdAt: DateTime.utc(2026, 1, 1),
            completedAt: Value(DateTime.utc(2026, 1, 2)),
            subject: 'ancient_history',
            mode: 'exam',
            status: 'completed',
            questionCount: attemptRows.length,
            isTimed: false,
          ),
        );
    for (final row in attemptRows) {
      await db.into(db.sessionQuestions).insert(row);
    }
  }

  test('getSessionResult counts danger zone and marks estimate', () async {
    const sid = 'sess-1';
    await seedQuestion('q1');
    await seedQuestion('q2');
    await seedQuestion('q3');
    await seedQuestion('q4');
    await seedQuestion('q5');

    final at = DateTime.utc(2026, 1, 2);
    await seedSessionWithAttempts(
      sid,
      attemptRows: [
        SessionQuestionsCompanion.insert(
          id: 'a1',
          sessionId: sid,
          questionUuid: 'q1',
          position: 1,
          selectedOption: const Value('b'),
          isCorrect: const Value(false),
          status: const Value('wrong'),
          attemptedAt: Value(at),
          confidence: const Value(AnswerConfidence.verySure),
        ),
        SessionQuestionsCompanion.insert(
          id: 'a2',
          sessionId: sid,
          questionUuid: 'q2',
          position: 2,
          selectedOption: const Value('b'),
          isCorrect: const Value(false),
          status: const Value('wrong'),
          attemptedAt: Value(at),
          confidence: const Value(AnswerConfidence.somewhatSure),
        ),
        SessionQuestionsCompanion.insert(
          id: 'a3',
          sessionId: sid,
          questionUuid: 'q3',
          position: 3,
          selectedOption: const Value('b'),
          isCorrect: const Value(false),
          status: const Value('wrong'),
          attemptedAt: Value(at),
          confidence: const Value(AnswerConfidence.guessing),
        ),
        SessionQuestionsCompanion.insert(
          id: 'a4',
          sessionId: sid,
          questionUuid: 'q4',
          position: 4,
          selectedOption: const Value('b'),
          isCorrect: const Value(false),
          status: const Value('wrong'),
          attemptedAt: Value(at),
        ),
        SessionQuestionsCompanion.insert(
          id: 'a5',
          sessionId: sid,
          questionUuid: 'q5',
          position: 5,
          selectedOption: const Value('a'),
          isCorrect: const Value(true),
          status: const Value('correct'),
          attemptedAt: Value(at),
          confidence: const Value(AnswerConfidence.verySure),
        ),
      ],
    );

    final repo = SessionHistoryRepositoryImpl(db);
    final r = await repo.getSessionResult(sid);

    expect(r.dangerZoneWrongCount, 2);
    expect(r.dangerZoneMarksEstimate, closeTo(1.32, 0.001));
    expect(r.confidenceSureTotal, 2);
    expect(r.confidenceSureCorrect, 1);
    expect(r.confidenceIntelligentTotal, 1);
    expect(r.confidenceIntelligentCorrect, 0);
    expect(r.confidencePureTotal, 1);
    expect(r.confidencePureCorrect, 0);
  });

  test('getSessionResult danger zone is zero when no confident wrongs', () async {
    const sid = 'sess-2';
    await seedQuestion('q10');
    await seedSessionWithAttempts(
      sid,
      attemptRows: [
        SessionQuestionsCompanion.insert(
          id: 'b1',
          sessionId: sid,
          questionUuid: 'q10',
          position: 1,
          selectedOption: const Value('a'),
          isCorrect: const Value(true),
          status: const Value('correct'),
          attemptedAt: Value(DateTime.utc(2026, 1, 2)),
        ),
      ],
    );

    final repo = SessionHistoryRepositoryImpl(db);
    final r = await repo.getSessionResult(sid);

    expect(r.dangerZoneWrongCount, 0);
    expect(r.dangerZoneMarksEstimate, 0.0);
  });
}
