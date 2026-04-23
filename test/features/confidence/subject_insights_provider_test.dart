import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:upsc_wars/core/database/user_db.dart';
import 'package:upsc_wars/core/domain/entities/answer_confidence.dart';
import 'package:upsc_wars/core/providers/user_database_provider.dart';
import 'package:upsc_wars/features/subject_detail/domain/subject_insights.dart';
import 'package:upsc_wars/features/subject_detail/providers/subject_insights_providers.dart';

void main() {
  late UserDatabase db;

  setUp(() async {
    db = UserDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedQuestion(String uuid, String topic) async {
    await db.into(db.questions).insert(
          QuestionsCompanion.insert(
            uuid: uuid,
            subject: 'ancient_history',
            topic: topic,
            subTopic: 'st',
            questionType: 'direct',
            correctOption: 'a',
            conceptAnchor: 'c',
            conceptsUsed: '[]',
            enDisplayText: const Value('Stem'),
          ),
        );
  }

  test('subjectInsightsProvider aggregates 30-day danger by subject and topics', () async {
    await seedQuestion('qa', 'TopicAlpha');
    await seedQuestion('qb', 'TopicBeta');
    await seedQuestion('qc', 'TopicGamma');

    const sessionId = 's-ins';
    final attempted = DateTime.now().subtract(const Duration(days: 1));

    await db.into(db.sessions).insert(
          SessionsCompanion.insert(
            id: sessionId,
            createdAt: attempted,
            completedAt: Value(attempted),
            subject: 'ancient_history',
            mode: 'exam',
            status: 'completed',
            questionCount: 4,
            isTimed: false,
          ),
        );

    Future<void> attempt({
      required String id,
      required String qid,
      required int pos,
      required String confidence,
    }) async {
      await db.into(db.sessionQuestions).insert(
            SessionQuestionsCompanion.insert(
              id: id,
              sessionId: sessionId,
              questionUuid: qid,
              position: pos,
              selectedOption: const Value('b'),
              isCorrect: const Value(false),
              status: const Value('wrong'),
              attemptedAt: Value(attempted),
              confidence: Value(confidence),
            ),
          );
    }

    await attempt(id: 'r1', qid: 'qa', pos: 1, confidence: AnswerConfidence.verySure);
    await attempt(id: 'r2', qid: 'qa', pos: 2, confidence: AnswerConfidence.somewhatSure);
    await attempt(id: 'r3', qid: 'qb', pos: 3, confidence: AnswerConfidence.verySure);
    await attempt(
      id: 'r4',
      qid: 'qc',
      pos: 4,
      confidence: AnswerConfidence.guessing,
    );

    final container = ProviderContainer(
      overrides: [
        userDatabaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);

    final insights = await container.read(
      subjectInsightsProvider('ancient_history').future,
    );

    expect(insights.dangerZoneCountLast30Days, 3);
    expect(insights.dangerZoneSureWrongCountLast30Days, 2);
    expect(insights.dangerZoneEducatedGuessWrongCountLast30Days, 1);
    expect(insights.dangerZoneMarksLast30, closeTo(1.98, 0.001));

    expect(insights.topicPercentiles, hasLength(2));
    final byTopic = {for (final t in insights.topicPercentiles) t.topic: t};
    expect(byTopic['TopicAlpha']!.dangerCount, 2);
    expect(byTopic['TopicBeta']!.dangerCount, 1);
    expect(byTopic['TopicAlpha']!.tier, RiskTier.high);
    expect(byTopic['TopicBeta']!.tier, RiskTier.medium);
  });
}
